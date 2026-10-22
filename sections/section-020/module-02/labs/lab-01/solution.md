# Solution: Make Flux Decrypt Secrets

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: the decryption settings and the identity in `sops-age`, the decrypted value in the cluster, the file in Git still encrypted, no identity in Git, and `podinfo` ready.

## Step 1: Ask Flux what is wrong

```sh
flux get kustomizations
flux events --for Kustomization/podinfo
kubectl -n podinfo get pods
```

The Flux `Kustomization` `podinfo` is not `Ready`, and its message and events point at the Secret `podinfo-db` in `apps/podinfo/secret.yaml`: kustomize-controller was asked to apply a SOPS-encrypted file without any decryption settings. The `podinfo` pods wait in `CreateContainerConfigError`, because the Secret they need does not exist with its real value.

## Step 2: Check which key the file needs

Start the port-forward in a second terminal, then compare the file's recipient with the team's identity:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
grep -oE 'age1[0-9a-z]+' fleet/apps/podinfo/secret.yaml
mkdir -p "$HOME/age-keys"
kubectl -n gitea get secret team-age-key -o jsonpath='{.data.age\.agekey}' | base64 -d > "$HOME/age-keys/team.agekey"
age-keygen -y "$HOME/age-keys/team.agekey"
```

Both commands print the same `age1` recipient, so the team's identity decrypts the file.

## Step 3: Create the Secret sops-age

```sh
kubectl -n flux-system create secret generic sops-age --from-file=age.agekey="$HOME/age-keys/team.agekey"
```

The key name `age.agekey` ends in `.agekey`, which kustomize-controller needs to read it as an age identity.

## Step 4: Turn on decryption

Save this as `kustomization-podinfo.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./apps/podinfo
  prune: true
  timeout: 3m
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo.yaml
```

Then check the result:

```sh
flux reconcile kustomization podinfo
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n podinfo rollout status deployment/podinfo
```

The Flux `Kustomization` is `Ready`, the password is `decrypted-by-flux`, and the rollout finishes with every replica ready. If the pods were created before the Secret existed, Kubernetes retries them; `kubectl -n podinfo rollout restart deployment/podinfo` starts fresh ones at once.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Decrypt the file and commit it in plain text | The password is in Git for everyone; the grader requires the encrypted file |
| Create `podinfo-db` with `kubectl` | `podinfo` starts, but Flux does not manage the Secret and the grader checks the decryption settings |
| Name the key `age.key` in `sops-age` | kustomize-controller ignores it, and decryption still fails |
| Commit `team.agekey` so Flux can find it | Flux does not read keys from Git, and the identity is now public |
