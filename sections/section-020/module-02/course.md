# Let Flux Decrypt Secrets In The Cluster

The repository holds the Secret `podinfo-db`, encrypted with SOPS, and the Flux `Kustomization` `podinfo` applies the folder it is in. Yet `podinfo` cannot start, because the Secret never arrives in the cluster with its password. Git holds the encrypted file, and nothing in the cluster holds the key to read it.

kustomize-controller, the Flux controller that builds and applies a Flux `Kustomization`, can decrypt SOPS files just before it applies them. It does that only when the Flux `Kustomization` asks for it, and only with a key it can reach.

Keep one sentence in mind: **Git holds the encrypted file, the cluster holds the identity, and kustomize-controller brings them together at apply time.** The decrypted value exists only in the Kubernetes Secret, never in Git and never in the artifact source-controller stores.

The module has two parts. **Decryption In kustomize-controller** gives the controller the age identity and turns on decryption, and a graded lab follows it. **Rotating Keys And Using A KMS** replaces a key without a gap and shows how a key management service removes the key file altogether.

## Learning objectives

After this module you can:

- Explain where in Flux a SOPS file is decrypted, and where the plain value exists afterwards.
- Read the reason a Flux `Kustomization` cannot apply an encrypted Secret from `flux get` and `flux events`.
- Store an age identity in the Secret `sops-age` in `flux-system`, under a key that ends in `.agekey`.
- Turn on decryption with `spec.decryption.provider: sops` and `spec.decryption.secretRef`.
- Add and remove recipients with `sops updatekeys`, and create a new data key with `sops rotate`.
- Explain how SOPS and Flux use AWS KMS, Google Cloud KMS, Azure Key Vault and HashiCorp Vault instead of an age identity.

## Before you start

You need to know how SOPS encrypts a file: values are encrypted with a data key, the data key is encrypted for each age recipient in the `sops:` block, and `.sops.yaml` holds the creation rules. You need basic Git and `kubectl`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Tools on your machine | `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2 |
| `gitops/fleet` | `.sops.yaml` with the team recipient, and `apps/podinfo/secret.yaml`, the Secret `podinfo-db` encrypted for it, listed in the Kustomize file `kustomization.yaml` |
| Flux v2.9.6 | The `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` (`./apps/podinfo`, `prune: true`), **without** decryption settings |
| `team-age-key` (namespace `gitea`) | A Secret that holds the team's age identity under the key `age.agekey`, so you can hand it to Flux |
| `podinfo` (namespace `podinfo`) | The application. It needs the Secret `podinfo-db`, which does not exist yet |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` on your machine while a port-forward to Gitea runs in a second terminal. The user `gitops` with the password `gitops-password` is lab-only.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
