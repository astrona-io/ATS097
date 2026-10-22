# Solution: Clean Every Credential Out Of The Repository

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: nothing secret on `main`, the three new values in the cluster, none of the three Secrets in the Flux inventory, `SMTP_PASSWORD` read from `podinfo-smtp`, and `podinfo` ready under a ready Flux `Kustomization`.

## Step 1: Find the three credentials

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Clone the repository and search the application folder:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
grep -rnE 'kind: Secret|password|token' apps/podinfo
```

Three files stand out. `secret.yaml` holds `podinfo-db` with a plain `stringData` password. `api-secret.yaml` holds `podinfo-api` with a `data` token, which is Base64; `base64 -d` shows it is `api-token-in-git`. `settings.yaml` is a ConfigMap `podinfo-settings` that holds `smtp-password` next to `smtp-host`. A ConfigMap is meant for settings that are not secret, so a password does not belong there at all.

## Step 2: Create the new SMTP Secret first

`podinfo-smtp` does not exist in Git, so Flux never prunes it. Create it before the Deployment needs it:

```sh
kubectl -n podinfo create secret generic podinfo-smtp --from-literal=password=rotated-smtp-2026
```

## Step 3: Change Git

In `apps/podinfo/deployment.yaml`, change the `SMTP_PASSWORD` entry so it reads from the Secret. The entry becomes:

```yaml
            - name: SMTP_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: podinfo-smtp
                  key: password
```

Save this as `apps/podinfo/settings.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-settings
  namespace: podinfo
data:
  smtp-host: smtp.example.com
```

Save this as `apps/podinfo/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - settings.yaml
  - deployment.yaml
  - service.yaml
```

Then delete the two Secret files, commit and push:

```sh
git rm apps/podinfo/secret.yaml apps/podinfo/api-secret.yaml
git commit -am "Move every credential out of Git"
git push
```

## Step 4: Let Flux prune, then create the two Secrets

Apply the commit now and check that the two old Secrets are gone:

```sh
flux reconcile kustomization podinfo --with-source
kubectl -n podinfo get secrets
```

`podinfo-db` and `podinfo-api` are no longer listed; kustomize-controller pruned them. `podinfo-smtp` is still there, because it never came from Git. Create the other two with their new values, then restart `podinfo`:

```sh
kubectl -n podinfo create secret generic podinfo-db --from-literal=password=rotated-db-2026
kubectl -n podinfo create secret generic podinfo-api --from-literal=token=rotated-api-2026
kubectl -n podinfo rollout restart deployment/podinfo
kubectl -n podinfo rollout status deployment/podinfo
```

The rollout finishes with every replica ready.

## Step 5: Check and submit

Check the Flux inventory and the ConfigMap in the cluster, then submit:

```sh
kubectl -n flux-system get kustomization podinfo \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
kubectl -n podinfo get configmap podinfo-settings -o yaml
astrona submit -c sections/section-010/capstone/labs/lab-01
```

The inventory lists the namespace, the ConfigMap, the Deployment and the Service, and no Secret. The ConfigMap holds only `smtp-host`.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Leave the SMTP password in the ConfigMap with a new value | A ConfigMap is not for secrets, and the new value is now in Git |
| Change the Deployment before `podinfo-smtp` exists | New pods cannot start until the Secret is created |
| Keep `api-secret.yaml` because its value "looks encrypted" | It is Base64; anyone decodes it |
| Create `podinfo-db` with the new value before the prune | The prune deletes it again |
