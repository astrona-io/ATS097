# Solution: Rotate A Leaked age Key

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: one new recipient in Git, only the new identity in `sops-age`, the new value in the cluster and only encrypted in Git, no identity in Git, and `podinfo` ready.

Because the old key leaked, there is no reason to keep it during the change: the old file and every older commit are already readable to whoever has it. The rotation can therefore be a clean replacement, done in an order that never leaves the cluster unable to decrypt.

## Step 1: Create the new key pair

```sh
mkdir -p "$HOME/age-keys"
age-keygen -o "$HOME/age-keys/rotated.agekey"
NEW_RECIPIENT="$(age-keygen -y "$HOME/age-keys/rotated.agekey")"
echo "$NEW_RECIPIENT"
```

## Step 2: Change Git to the new recipient and the new value

Start the port-forward in a second terminal, then clone:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
```

Save this as `.sops.yaml`, with the new recipient in place of `<NEW_RECIPIENT>`:

```yaml
creation_rules:
  - path_regex: .*\.yaml$
    encrypted_regex: ^(data|stringData)$
    age: <NEW_RECIPIENT>
```

The value changes too, so write the Secret again in plain text and encrypt it from scratch with the new rule. A fresh encryption creates a new data key, so nothing in the new file depends on the leaked key. Save this as `apps/podinfo/secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-db
  namespace: podinfo
type: Opaque
stringData:
  password: after-key-rotation
```

Encrypt it before Git sees it, and check the recipient:

```sh
sops --encrypt --in-place apps/podinfo/secret.yaml
grep -oE 'age1[0-9a-z]+' apps/podinfo/secret.yaml
```

The file lists one recipient, the new one.

## Step 3: Replace the identity in the cluster, then push

Replace `sops-age` first, so the identity is ready when Flux fetches the new commit:

```sh
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$HOME/age-keys/rotated.agekey" --dry-run=client -o yaml | kubectl apply -f -
git commit -am "Rotate the leaked age key and the podinfo-db password"
git push
```

Between these two commands, the cluster cannot decrypt the old file, but the Flux `Kustomization` only applies again after the push brings the new file. If Flux reconciles in between, it reports a decryption error once and recovers on the next run.

## Step 4: Apply and check

```sh
flux reconcile kustomization podinfo --with-source
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n podinfo rollout restart deployment/podinfo
kubectl -n podinfo rollout status deployment/podinfo
```

The Flux `Kustomization` is `Ready`, the password is `after-key-rotation`, and the restarted pods read it.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `sops updatekeys` to the new recipient but keep the old value | Git history still holds the old file, which the leaked identity decrypts; the value is known |
| Keep the leaked recipient as a second recipient | Every new value is readable with the leaked identity |
| Add the new identity to `sops-age` and keep the leaked one | Harmless for decryption, but the leaked identity stays active in the cluster; the grader rejects it |
| Push before replacing `sops-age` | Flux cannot decrypt the new file until the identity arrives |
