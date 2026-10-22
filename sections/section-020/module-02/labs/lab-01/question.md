# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** SOPS decryption

## Scenario

The team moved the database password of `podinfo` into Git, encrypted with SOPS for the team's age key. Since that commit, `podinfo` cannot start new pods, and the Flux `Kustomization` `podinfo` is not `Ready`. The file in Git is correct. The team's identity is in the Secret `team-age-key` in the namespace `gitea`.

## Your task

1. Find out, from Flux itself, why the Flux `Kustomization` `podinfo` cannot apply the Secret.
2. Give kustomize-controller the team's identity in a Secret named `sops-age` in `flux-system`.
3. Make the Flux `Kustomization` `podinfo` decrypt SOPS files with that Secret.
4. Make sure `podinfo` runs with all its replicas ready.

## Constraints

- Do not change, decrypt or replace the encrypted file in Git.
- Do not commit any age identity.
- Keep `prune: true` on the Flux `Kustomization` `podinfo`, and do not suspend it.
- Do not create the Secret `podinfo-db` yourself; Flux must create it from Git.

## Done when

- The Flux `Kustomization` `podinfo` sets `decryption.provider: sops` and `decryption.secretRef.name: sops-age`, and `sops-age` holds the team's identity under a key ending in `.agekey`.
- The Secret `podinfo-db` in `podinfo` holds the decrypted password.
- `apps/podinfo/secret.yaml` on `main` is still encrypted, and no file on `main` contains an age identity.
- The Flux `Kustomization` `podinfo` is `Ready`, and every `podinfo` replica is ready.
