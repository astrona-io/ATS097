# Connecting A Git Server To A Receiver

A Receiver on its own waits for requests that never come. The Git server must know its address and the token to sign with. This part creates the token, the Receiver and a push webhook in Gitea, and then pushes a commit to see source-controller fetch it within seconds, while the interval stays one hour.

## Create the token and the Receiver

The token is a random string that only Gitea and the cluster know. Generate one and store it in a Secret with the key `token`. Keep it in a shell variable too, because Gitea needs the same value:

<!-- astrona:playground:renew -->

```sh
TOKEN="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
kubectl -n flux-system create secret generic receiver-token --from-literal=token="$TOKEN"
```

Now the Receiver. It uses the `github` type for Gitea, acts on `ping` and `push` events, and reconciles the `GitRepository` `fleet`. Save this as `receiver-gitea.yaml`:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: gitea-receiver
  namespace: flux-system
spec:
  type: github
  events:
    - "ping"
    - "push"
  secretRef:
    name: receiver-token
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: GitRepository
      name: fleet
```

Apply it:

```sh
kubectl apply -f receiver-gitea.yaml
```

Then read its state and its webhook path:

```sh
flux get receivers
HOOK_PATH="$(kubectl -n flux-system get receiver gitea-receiver -o jsonpath='{.status.webhookPath}')"
echo "$HOOK_PATH"
```

The Receiver is `Ready`, and the path starts with `/hook/` followed by a long hash.

## Add the push webhook in Gitea

Gitea runs inside the cluster, so it can call the Receiver at its Service address directly; nothing needs to be exposed to the internet. Gitea refuses webhook targets on private addresses by default, and the playground's Gitea allows them with the setting `ALLOWED_HOST_LIST=private`. A Gitea on the internet would instead call a public address in front of `webhook-receiver`, for example an Ingress.

You can add a webhook in the Gitea web interface under the repository's settings, or through the Gitea API. The API keeps it in one command. Start the port-forward in a second terminal if it is not running. Then save the webhook as a file, putting the value of `$TOKEN` and of `$HOOK_PATH` in place of the placeholders. Save this as `webhook-fleet.json`:

```json
{
  "type": "gitea",
  "active": true,
  "events": ["push"],
  "branch_filter": "*",
  "config": {
    "url": "http://webhook-receiver.flux-system.svc.cluster.local<HOOK_PATH>",
    "content_type": "json",
    "secret": "<TOKEN>"
  }
}
```

Create it:

```sh
curl -s -u gitops:gitops-password -H 'Content-Type: application/json' \
  --data @webhook-fleet.json http://gitea.localtest.me:3000/api/v1/repos/gitops/fleet/hooks | jq '.id, .config.url'
```

Gitea answers with the new webhook's number and the address it calls. From now on, Gitea sends a signed request to the Receiver after every push to `gitops/fleet`. The `secret` field is the token Gitea uses for the HMAC signature, so it must be the same string as the `token` in the Secret `receiver-token`.

## Prove it with a push

Make a small change, push it, and watch the revision of the `GitRepository`:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
date > clusters/kind/last-push.txt
git add clusters/kind/last-push.txt && git commit -m "Test the webhook" && git push
git rev-parse HEAD
flux get sources git
```

Within a few seconds, `flux get sources git` shows a revision that ends with the commit hash `git rev-parse` printed. Run it again if it still shows the old one. Without the webhook, that would take up to an hour. If the revision does not change, open `http://gitea.localtest.me:3000/gitops/fleet/settings/hooks` in your browser, sign in as `gitops`, open the webhook and read its recent deliveries: Gitea shows the response code of each request. A `401` or `403` means the signature did not match the token, and a connection error means the address is wrong.

You can now connect a Git server to a Receiver and prove that a push reaches the cluster within seconds. That completes the loop: Git holds the desired state, and the cluster learns about every change the moment it is pushed.

## Common pitfalls

> [!WARNING]
> - **Different tokens in Gitea and in `receiver-token`.** notification-controller rejects every request. The two values must be identical.
> - **Using the address from before a token change.** The webhook path depends on the token. Read `.status.webhookPath` again after any change.
> - **Listing the wrong object in `spec.resources`.** notification-controller accepts the request but reconciles another object, or none. The `GitRepository` named there must exist in the given namespace.
> - **Checking the Flux `Kustomization` only.** The webhook makes source-controller fetch; kustomize-controller then applies the new revision because the source changed. Check the source first.

## Your mission: Reconcile On Every Push

You can now create a Receiver, connect a Gitea push webhook to it, and prove the effect. The graded lab gives you a cluster whose `GitRepository` polls once an hour, and asks you to make every push reach the cluster within seconds without changing that interval.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-097-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-097-lab-030-01
astrona start ats-097-playground-030-01
```
