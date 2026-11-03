# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Sops tenants

## Scenario

Two tenants have their own folders in Git, `tenants/a` and `tenants/b`, each with a Secret encrypted for the tenant's own age key. Both Flux `Kustomization` objects, `tenant-a` and `tenant-b`, use the decryption Secret `sops-age`, which holds only the key of tenant a. Tenant b does not get its Secret. The identities are in the Secrets `tenant-a-key` and `tenant-b-key` in the namespace `gitea`.

## Your task

1. Find, from Flux, why `tenant-b` is not `Ready`.
2. Give `tenant-b` its own decryption Secret named `sops-age-b` in `flux-system`, holding the identity of tenant b under a key ending in `.agekey`.
3. Point `tenant-b` at that Secret.

## Constraints

- Do not add the identity of tenant b to `sops-age`; tenant a must not be able to read tenant b's files.
- Do not change or decrypt the files in Git, and do not commit any identity.
- Keep `prune: true` on both Kustomizations.

## Done when

- `tenant-b` uses `decryption.secretRef.name: sops-age-b`, and `sops-age-b` holds the identity of tenant b.
- `sops-age` still holds only the identity of tenant a.
- Both Kustomizations are `Ready`, the Secret `app-secret` in `tenant-a` holds `value-a` and the one in `tenant-b` holds `value-b`.
- Both files under `tenants/` on `main` are still encrypted.
