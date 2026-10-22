# Solution: Remove A Plain Secret From Git

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: no plain Secret or new value on `main`, the new password in the cluster, the Secret no longer in the Flux inventory, and `podinfo` ready under a ready Flux `Kustomization`.

## Step 1: Clone the repository and look at the Secret

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Clone the repository and read the Secret and its history:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
cat apps/podinfo/secret.yaml
git log --oneline -- apps/podinfo/secret.yaml
```

The file holds the Secret `podinfo-db` with `password: s3cr3t-in-git` under `stringData`, and the log lists the commit that added it. That commit stays in history whatever you do now, which is why the password must change.

## Step 2: Remove the Secret from Git

Save this as `apps/podinfo/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
```

Delete the file, commit and push:

```sh
git rm apps/podinfo/secret.yaml
git commit -am "Remove the plain podinfo-db Secret"
git push
```

## Step 3: Let Flux apply the change

Ask Flux to fetch and apply the new commit now, then check the Secret:

```sh
flux reconcile kustomization podinfo --with-source
kubectl -n podinfo get secret podinfo-db
```

The reconcile reports the new revision, and the Secret is not found: kustomize-controller pruned it, because it was in the inventory and is no longer in Git. Running pods still work. A pod started now could not find its Secret.

## Step 4: Create the Secret with the new password

Create the Secret outside Git and restart `podinfo`, so the pods read the new value:

```sh
kubectl -n podinfo create secret generic podinfo-db --from-literal=password=rotated-db-password
kubectl -n podinfo rollout restart deployment/podinfo
kubectl -n podinfo rollout status deployment/podinfo
```

The rollout finishes with all replicas ready.

## Step 5: Check the result

Confirm the value, the inventory and the Flux `Kustomization`:

```sh
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n flux-system get kustomization podinfo \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
flux get kustomizations
```

The password is `rotated-db-password`, the inventory lists the namespace, the Deployment and the Service but no Secret, and the Flux `Kustomization` `podinfo` is `Ready`.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create the new Secret first, then remove the file | If the Secret is still in the inventory, the prune deletes it, new value and all |
| Delete `secret.yaml` but keep it in `kustomization.yaml` | The Kustomize build fails and the Flux `Kustomization` stops applying anything |
| Commit the new value as Base64 under `data` | Anyone decodes it; the grader finds the value in Git |
| Set `prune: false` so the Secret survives | The Secret stays, but so does the old password unless you change it, and the grader requires `prune: true` |

## Practice on your own

- Repeat the task with the annotation `kustomize.toolkit.fluxcd.io/prune: disabled` on the Secret in a first commit, so the Secret is never deleted.
- Run `git log -p` on the deleted file after your push, and confirm the old password is still in history.
