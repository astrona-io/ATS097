# Solution: Reconcile On Every Push

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the Receiver, the Gitea webhook, the unchanged interval, and a push of its own that must reach source-controller within a minute.

## Step 1: Create the token

```sh
TOKEN="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
kubectl -n flux-system create secret generic receiver-token --from-literal=token="$TOKEN"
```

Keep this terminal open: `$TOKEN` is needed again for Gitea.

## Step 2: Create the Receiver

Save this as `receiver-gitea.yaml`:

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

Then read its path:

```sh
flux get receivers
HOOK_PATH="$(kubectl -n flux-system get receiver gitea-receiver -o jsonpath='{.status.webhookPath}')"
echo "http://webhook-receiver.flux-system.svc.cluster.local$HOOK_PATH"
```

The Receiver is `Ready`, and the last command prints the full webhook address.

## Step 3: Add the webhook in Gitea

Start the port-forward in a second terminal. Save this as `webhook-fleet.json`, with the address from step 2 and the value of `$TOKEN` in place of the placeholders:

```json
{
  "type": "gitea",
  "active": true,
  "events": ["push"],
  "branch_filter": "*",
  "config": {
    "url": "<WEBHOOK_ADDRESS>",
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

## Step 4: Prove it with a push

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
date > clusters/kind/last-push.txt
git add clusters/kind/last-push.txt && git commit -m "Test the webhook" && git push
git rev-parse HEAD
flux get sources git
```

Within a few seconds, the revision of `fleet` ends with the hash `git rev-parse` printed. If it does not, read the webhook's recent deliveries in the Gitea web interface under the repository's settings.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set the interval to `30s` | Pushes arrive fast, but the Git server gets constant requests; the grader requires 30 minutes or more |
| Use the `generic` type | Works, but anyone who learns the path can trigger reconciliations; the grader requires `github` |
| Point the Receiver at the Flux `Kustomization` | kustomize-controller applies the old artifact again; source-controller still waits for the interval |
| Different token in Gitea | notification-controller rejects every request; nothing reaches the cluster |
