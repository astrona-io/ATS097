# Summary

An encrypted Secret in Git reaches the cluster only when something there can decrypt it. This module gave that job to kustomize-controller, then changed its key without a gap and looked at services that keep the key out of reach altogether.

## What you learned

source-controller stores the repository as Git holds it, so the Secret is still encrypted in the artifact. kustomize-controller decrypts SOPS values after it builds the path and before it applies the objects, but only when the Flux `Kustomization` sets `spec.decryption.provider: sops` and names a Secret in `spec.decryption.secretRef`. That Secret lives in the namespace of the Flux `Kustomization`, usually `flux-system` and usually named `sops-age`, and every key in it whose name ends in `.agekey` is read as an age identity. Without it, the Flux `Kustomization` cannot apply the encrypted Secret, and `flux get` and `flux events` say so. The plain value exists only in the resulting Kubernetes Secret.

A key is rotated in a fixed order so that the cluster can always decrypt what Git holds. Add the new identity to `sops-age`, add the new recipient to `.sops.yaml` and run `sops updatekeys`, then remove the old recipient, run `updatekeys` again and `sops rotate` for a new data key, and finally remove the old identity. Git history keeps every old version encrypted for the old recipient, so after a leak every value the leaked identity protected must change.

A key management service keeps the key inside AWS KMS, Google Cloud KMS, Azure Key Vault or HashiCorp Vault. `.sops.yaml` then names that key, and kustomize-controller decrypts through permissions given to its service account, or with a Vault token in the key `sops.vault-token`. No identity file exists to leak. The key facts to remember are these:

- Decryption happens in kustomize-controller, at apply time, never in Git or in the artifact.
- The identity Secret must be in the Flux `Kustomization`'s namespace, with keys ending in `.agekey`.
- During a rotation, the cluster must hold an identity for every recipient the file in Git uses.
- A leaked identity means new values, not only a new key.

<!-- astrona:playground:destroy -->
