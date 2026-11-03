# Decryption Settings In Detail

The two lines `provider: sops` and `secretRef` are enough for a first success, but the real behaviour has more rules: which files get decrypted, which key names the Secret may use, what the applied Secret looks like, and where the identity is kept so it survives a rebuilt cluster. This part lists those rules so that a setup you design on your own behaves as you expect.

## The fields of spec.decryption

A Flux `Kustomization` has one block for decryption. Save this as `kustomization-podinfo.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo
  prune: true
  sourceRef:
    kind: GitRepository
    name: fleet
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo.yaml
```

`provider` has one valid value, `sops`. `secretRef.name` names a Secret in the namespace of the Kustomization. The field `serviceAccountName` is a third option: it makes kustomize-controller use the cloud identity bound to that service account to call a key management service, so no key file is needed. A Kustomization needs either a secret, a service account, or controller-wide credentials. The choice depends on whether the cluster can reach a key management service.

## Key names in the identity Secret

kustomize-controller looks at the data keys of the Secret and chooses the decryption method by the key name. The suffix is what counts:

| Key suffix or name | What it holds |
| --- | --- |
| `.agekey` | An age identity, one or more `AGE-SECRET-KEY-1` lines |
| `.asc` | An ASCII-armored PGP private key |
| `sops.vault-token` | A HashiCorp Vault token |

Cloud key management credentials use their own key names in the same Secret; the Flux documentation lists them. A Secret can hold several keys at once, for example one age identity for new files and an older one for files that are not yet re-encrypted. kustomize-controller tries all of them.

## What is decrypted and what is applied

kustomize-controller builds the path with Kustomize, then decrypts every SOPS-encrypted file it finds in the output, including files that a `secretGenerator` reads. Two facts follow from this. A file that no `kustomization.yaml` includes is never decrypted and never applied, which is how the `secrets/` folder of the playground repository stays inert. A file that is included but not encrypted passes through unchanged.

The result that reaches the API server is a normal Secret. The `sops:` block is removed, the values are plain, and `kubectl get secret` shows them Base64-encoded as for any Secret. The decrypted text is held in memory during the reconcile. source-controller's stored artifact still holds the encrypted file, so the plain value never leaves the cluster's Secret objects.

## Keep the identity outside Git

The identity must exist in the cluster before the first reconcile, and it must never be committed. Two ways keep this safe. You create the Secret by hand or from a script when the cluster is built, with `kubectl create secret generic sops-age --from-file=age.agekey=<file>`, which is what the playground does. Or you rely on a key management service, so no identity file exists. In both cases keep a copy of the identity in a password manager or a vault. If the cluster is lost and the only copy of the identity was in it, every encrypted file in Git is lost with it.

You now have the complete list of the decryption settings, the key name rules and the rules for what gets decrypted. The module closes with a summary of how the encrypted file and the identity meet at apply time.

## Common pitfalls

> [!WARNING]
> - **Creating `sops-age` in another namespace.** The Secret must be in the namespace of the Kustomization that uses it.
> - **Naming the key `age.agekey.txt`.** The name must end in `.agekey`. Anything else is ignored.
> - **Committing the `secrets/` folder into a built path.** Once a `kustomization.yaml` includes the file, the Kustomization applies it.
> - **Keeping the only copy of the identity in the cluster.** Back it up outside the cluster.
