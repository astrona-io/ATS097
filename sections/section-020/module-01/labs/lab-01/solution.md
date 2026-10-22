# Solution: Encrypt A Secret For Git

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the rule in `.sops.yaml`, the encrypted file's shape and recipient, that the team identity decrypts it to the right value, and that no identity is committed.

## Step 1: Get the team recipient

The recipient is public, so the team publishes it in a ConfigMap:

```sh
RECIPIENT="$(kubectl -n flux-system get configmap sops-recipient -o jsonpath='{.data.recipient}')"
echo "$RECIPIENT"
```

The output starts with `age1`. That is all you need to encrypt for the team.

## Step 2: Clone the repository

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Then clone:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
```

## Step 3: Write the creation rule

Save this as `.sops.yaml`, with the recipient from step 1 in place of `<RECIPIENT>`:

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    age: <RECIPIENT>
```

## Step 4: Write and encrypt the Secret

Save this as `secrets/podinfo/secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-db
  namespace: podinfo
type: Opaque
stringData:
  password: encrypted-in-git
```

Encrypt it before you add anything to Git, and look at the result:

```sh
sops --encrypt --in-place secrets/podinfo/secret.yaml
cat secrets/podinfo/secret.yaml
```

`kind` and `metadata` are unchanged, the password is an `ENC[...]` value, and the `sops:` block lists the team recipient under `age`.

## Step 5: Commit and push

```sh
git add .sops.yaml secrets/podinfo/secret.yaml
git commit -m "Add the encrypted podinfo-db Secret"
git push
```

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

You cannot decrypt the file yourself, because you do not hold the team's identity. The grader can; it is the check that you encrypted for the right recipient.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Commit the plain file, then encrypt and commit again | The password is in the first commit forever |
| Encrypt for your own new key | The team cannot decrypt it; the grader checks the recipient |
| Leave out `encrypted_regex` | `metadata.name` is encrypted too and the object is no longer readable |
| Base64-encode the value under `data` instead of encrypting | Anyone can decode it |
