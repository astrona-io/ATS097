# PGP End To End

PGP is the one non-age key type you can try without a cloud account, and it shows every step that a KMS also needs: create a key, list it in a rule, encrypt, give the private half to the cluster, decrypt. This part runs the whole flow with a PGP key that has no passphrase, because the controller cannot type one.

## Create a key without a passphrase

GnuPG (`gpg`) must be installed on your machine. Create a key for the exercise and keep its fingerprint, a 40-character identifier, in a variable:

<!-- astrona:playground:renew -->

```sh
gpg --batch --passphrase '' --quick-generate-key "flux-sops-demo" default default never
KEY_FP="$(gpg --list-secret-keys --with-colons flux-sops-demo | awk -F: '/^fpr:/ {print $10; exit}')"
echo "$KEY_FP"
```

The key never expires and has no passphrase. A key with a passphrase cannot be used by kustomize-controller. Real keys for a cluster should be created only for this purpose, and never reused for email or signing.

## Encrypt for the fingerprint

Clone the repository, then write a rule that uses the fingerprint. Save this as `.sops.yaml`, with your fingerprint in place of `<FINGERPRINT>`:

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    pgp: <FINGERPRINT>
```

Save a Secret as `secrets/podinfo/podinfo-db.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-db
  namespace: podinfo
stringData:
  password: pgp-protected-value
```

Encrypt it in place and read the result:

```sh
sops --encrypt --in-place secrets/podinfo/podinfo-db.yaml
grep -A3 'pgp:' secrets/podinfo/podinfo-db.yaml
```

The `sops:` block now lists a `pgp` entry with your fingerprint and the encrypted data key. SOPS needs only the public key to encrypt. Running `sops --decrypt` on the file prints the value, because your GnuPG keyring holds the private key.

## Give the private key to the cluster

Export the private key in ASCII-armored form and store it in a Secret. The key name must end in `.asc`:

```sh
gpg --export-secret-keys --armor "$KEY_FP" | kubectl -n flux-system create secret generic sops-gpg --from-file=sops.asc=/dev/stdin
```

Then turn decryption on for the Flux `Kustomization`, pointing at that Secret. Save this as `kustomization-podinfo.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  path: ./secrets/podinfo
  prune: true
  sourceRef:
    kind: GitRepository
    name: fleet
  decryption:
    provider: sops
    secretRef:
      name: sops-gpg
```

Apply it, push the encrypted file to Git, and reconcile:

```sh
kubectl apply -f kustomization-podinfo.yaml
flux reconcile kustomization podinfo --with-source
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
```

The Secret holds the plain value `pgp-protected-value`, and Git holds only the encrypted file. kustomize-controller used the `.asc` key from `sops-gpg` to recover the data key. The path `./secrets/podinfo` contains the Secret file only, so a `kustomization.yaml` is generated for it by the Kustomization.

You can now run the whole flow with a PGP key. Every cloud key type follows the same flow, with a different place for the private half. The last part moves files between key types.

## Common pitfalls

> [!WARNING]
> - **Using a key with a passphrase.** The controller cannot unlock it, and decryption fails.
> - **Naming the Secret key anything but `.asc` at the end.** It is ignored.
> - **Exporting the public key by mistake.** `--export-secret-keys` exports the private key. `--export` exports only the public one.
> - **Leaving the exported private key file on disk.** Pipe it straight into the Secret, as above.
