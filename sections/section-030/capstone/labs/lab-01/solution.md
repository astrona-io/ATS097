# Solution: Deliver A Rotated Secret Without Waiting

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: the Receiver, the interval, the delivered and still-encrypted Secret, no identity in Git, and a push of its own that must reach source-controller within a minute.

## Step 1: Read the Receiver

```sh
flux get receivers
kubectl -n flux-system get receiver gitea-receiver -o yaml
```

The Receiver is ready and has a webhook path, but `spec.resources` names a `GitRepository` called `flux-system`. This cluster has no such object; the one Flux fetches is `fleet`. A valid request would reconcile nothing useful.

## Step 2: Read the webhook deliveries

Start the port-forward in a second terminal, open `http://gitea.localtest.me:3000/gitops/fleet/settings/hooks` in your browser, sign in as `gitops`, and open the webhook. Its recent deliveries show requests that notification-controller rejected. The address is right, so the signature is wrong: the webhook's secret is not the token in `receiver-token`.

## Step 3: Fix the Receiver

```sh
kubectl -n flux-system patch receiver gitea-receiver --type=json \
  -p '[{"op":"replace","path":"/spec/resources/0/name","value":"fleet"}]'
```

The Receiver object is not in Git in this lab, so a patch is enough. In a repository where Flux applies the Receiver from Git, change it in Git instead.

## Step 4: Replace the webhook

Gitea does not change a webhook's secret through the API: a `PATCH` with a new `config.secret` answers `200`, but the webhook keeps signing with the old secret. So delete the webhook and create it again with the right secret.

Read the token and the webhook path, and find the webhook's number:

```sh
TOKEN="$(kubectl -n flux-system get secret receiver-token -o jsonpath='{.data.token}' | base64 -d)"
HOOK_PATH="$(kubectl -n flux-system get receiver gitea-receiver -o jsonpath='{.status.webhookPath}')"
curl -s -u gitops:gitops-password http://gitea.localtest.me:3000/api/v1/repos/gitops/fleet/hooks | jq '.[] | .id'
```

Delete it, with its number in place of `<HOOK_ID>`:

```sh
curl -s -o /dev/null -w '%{http_code}\n' -u gitops:gitops-password -X DELETE \
  http://gitea.localtest.me:3000/api/v1/repos/gitops/fleet/hooks/<HOOK_ID>
```

Gitea answers `204`. Save this as `webhook-fleet.json`, with the full address (`http://webhook-receiver.flux-system.svc.cluster.local` followed by `$HOOK_PATH`) and the token in place of the placeholders:

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

Create the new webhook:

```sh
curl -s -u gitops:gitops-password -H 'Content-Type: application/json' \
  --data @webhook-fleet.json http://gitea.localtest.me:3000/api/v1/repos/gitops/fleet/hooks | jq '.id, .config.url'
```

## Step 5: Rotate the password in Git

Copy the identity Flux uses to a file outside the repository, clone, and edit the Secret through `sops`:

```sh
mkdir -p "$HOME/age-keys"
kubectl -n flux-system get secret sops-age -o jsonpath='{.data.age\.agekey}' | base64 -d > "$HOME/age-keys/team.agekey"
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
SOPS_AGE_KEY_FILE="$HOME/age-keys/team.agekey" sops apps/podinfo/secret.yaml
```

In the editor, change the value of `password` to `delivered-by-webhook`, save and close. SOPS encrypts the file again. Then push and watch, without any reconcile command:

```sh
git commit -am "Rotate the podinfo-db password"
git push
git rev-parse HEAD
flux get sources git
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
```

Within a few seconds the revision of `fleet` holds your commit, kustomize-controller applies it because its source changed, and the Secret holds `delivered-by-webhook`. Restart `podinfo` with `kubectl -n podinfo rollout restart deployment/podinfo` so its pods read the new value.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Lower the interval so changes arrive anyway | The webhook stays broken; the grader requires 30 minutes or more |
| Fix only the token | Valid requests now reconcile a `GitRepository` that does not exist |
| Fix only the Receiver's resource | Every request is still rejected for a bad signature |
| Replace the encrypted file with a plain Secret "to be quick" | The password is in Git; the grader rejects it |
