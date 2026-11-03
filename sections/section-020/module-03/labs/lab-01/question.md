# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Sops keys

## Scenario

The team encrypted the `podinfo-db` Secret in Git for one age key, and Flux decrypts it with the Secret `sops-age`. Nobody else can decrypt the file if that key is lost. A backup identity exists in the Secret `backup-age-key` in the namespace `gitea`, and the team's identity is in `team-age-key` in the same namespace.

## Your task

1. Add the backup identity's recipient to the creation rule in `.sops.yaml`, next to the team's recipient.
2. Update `apps/podinfo/secret.yaml` so that both identities can decrypt it. Use the team identity to run the update.
3. Commit and push both files to `main`.

## Constraints

- Keep the file encrypted in Git, and do not commit any age identity.
- Do not change the decrypted value `decrypted-by-flux`.
- Do not change `sops-age` in the cluster.

## Done when

- `.sops.yaml` and `apps/podinfo/secret.yaml` on `main` both list the recipient of the team identity and the recipient of the backup identity.
- The backup identity can decrypt `apps/podinfo/secret.yaml`.
- The Flux `Kustomization` `podinfo` is `Ready` and the Secret `podinfo-db` holds `decrypted-by-flux`.
