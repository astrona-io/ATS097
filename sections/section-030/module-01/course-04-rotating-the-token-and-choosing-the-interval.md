# Rotating The Token And Choosing The Interval

A token that never changes is a risk the day someone who knew it leaves, or the day it appears in a log. Replacing it is simple, but it moves the webhook path, so the Git server stops reaching the Receiver until you update it. This part walks through a token rotation, shows how to trigger a reconcile by hand while you fix a webhook, and explains how to choose the polling interval that stays as the safety net.

## Rotate the token

The token lives in two places: the Secret `receiver-token` in the cluster and the secret field of the webhook in the Git server. Replace the value in the cluster first. Create a new random value and update the Secret:

<!-- astrona:playground:renew -->

```sh
NEW_TOKEN="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
kubectl -n flux-system create secret generic receiver-token --from-literal=token="$NEW_TOKEN" --dry-run=client -o yaml | kubectl apply -f -
```

The first command builds a new Secret manifest without sending it, and `kubectl apply` replaces the stored value. notification-controller sees the change, reconciles the Receiver and writes a new `.status.webhookPath`, because the path is a hash of the token, the name and the namespace. Read the new path:

```sh
kubectl -n flux-system get receiver gitea-receiver -o jsonpath='{.status.webhookPath}{"\n"}'
```

The old path no longer exists. Every push now fails until the webhook in Gitea uses the new path and signs with the new token. Update the webhook with the Gitea API, putting the new path and `$NEW_TOKEN` in a file in the same format the webhook had when you created it, and send it with a `PATCH` request to the webhook's address under `/api/v1/repos/gitops/fleet/hooks/`.

## Trigger a reconcile by hand

While the webhook is broken, you can still make source-controller fetch at once. The Flux command line does what the Receiver does:

```sh
flux reconcile source git fleet
```

The command sets the annotation `reconcile.fluxcd.io/requestedAt` on the `GitRepository` to the current time. source-controller sees a new value in that annotation and fetches immediately. A Receiver does the same thing for every object in `spec.resources`, so a successful webhook leaves the same annotation behind. Read it to learn when the last request arrived:

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.metadata.annotations.reconcile\.fluxcd\.io/requestedAt}{"\n"}'
```

The value is the time of the last request, whether it came from the Receiver or from your own command.

## Choose the interval

With a working webhook, the interval has one job: to catch a push whose webhook was lost, for example while notification-controller restarted or the network dropped the request. The interval can therefore be long. A typical choice is ten minutes to an hour. A very short interval puts the load back on the Git server that the webhook was meant to remove, and a very long one lets a lost webhook leave the cluster behind for hours.

The interval also covers changes that no webhook announces, such as a branch that was reset by a different tool. Pick a value you can accept as the worst-case delay, and monitor that the revision follows the branch.

You can now rotate the token without losing deliveries for long, force a fetch by hand, and choose an interval for a cluster that relies on a webhook. The module closes with a summary of the whole route from push to revision.

## Common pitfalls

> [!WARNING]
> - **Rotating the Secret and forgetting the webhook.** The Git server keeps calling the old path, and every push fails until you update it.
> - **Updating the path and forgetting the signing token.** The path matches, but the signature does not, so the request is still rejected.
> - **Setting a one-minute interval to hide a broken webhook.** The cluster looks fine and loads the Git server. Fix the webhook and keep the long interval.
