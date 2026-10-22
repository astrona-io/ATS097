# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** SOPS encryption

## Scenario

The team that runs `podinfo` wants its database Secret back in Git, encrypted. The team has one age key pair. Its recipient is published in the ConfigMap `sops-recipient` in the namespace `flux-system`; its identity is kept by the team and is not given to you.

## Your task

In the repository `gitops/fleet`, on the branch `main`:

1. Add a `.sops.yaml` at the repository root with a creation rule that:
   - applies to YAML files under `secrets/`,
   - encrypts only the keys `data` and `stringData`,
   - encrypts for the team's age recipient.
2. Add the file `secrets/podinfo/secret.yaml`: a Secret named `podinfo-db` in the namespace `podinfo`, with the key `password` set to `encrypted-in-git`, encrypted with SOPS.
3. Commit and push both files.

## Constraints

- The value `encrypted-in-git` must never appear in Git in plain text, in any commit.
- `kind` and `metadata` must stay readable in the encrypted file.
- Do not commit any age identity.

## Done when

- `.sops.yaml` names the team recipient and encrypts only `data` and `stringData`.
- `secrets/podinfo/secret.yaml` has a `sops:` block for the team recipient, readable `kind` and `metadata.name`, and no plain password.
- The team's identity decrypts the file to `password: encrypted-in-git`.
- No file on `main` contains an age identity.
