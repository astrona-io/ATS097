# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Key rotation

## Scenario

The age identity that Flux uses to decrypt the Secrets of `podinfo` was pasted into a public chat. It is the identity in the Secret `sops-age` in `flux-system`, and its recipient is the one in `.sops.yaml` and in `apps/podinfo/secret.yaml`. Treat that key and every value it protected as known.

## Your task

1. Create a new age key pair. Keep the identity out of Git.
2. Make Git use only the new key: `.sops.yaml` names only the new recipient, and `apps/podinfo/secret.yaml` is encrypted for the new recipient only.
3. Give the Secret `podinfo-db` (key `password`) the new value `after-key-rotation`, committed encrypted.
4. Make the Secret `sops-age` hold the new identity, and not the leaked one.
5. Make sure Flux applies the new value and `podinfo` runs with it.

## Constraints

- The leaked recipient must not appear in `.sops.yaml` or in `apps/podinfo/secret.yaml`, not even as a second recipient.
- Do not commit any age identity, and do not commit `after-key-rotation` in plain text.
- Keep `prune: true` and the decryption settings on the Flux `Kustomization` `podinfo`, and do not suspend it.

## Done when

- `.sops.yaml` and `apps/podinfo/secret.yaml` name exactly one recipient, the same one, and it is not the leaked one.
- `sops-age` holds the identity for that recipient and not the leaked identity.
- The Secret `podinfo-db` holds `after-key-rotation`, and Git holds that value only encrypted.
- No file on `main` contains an age identity.
- The Flux `Kustomization` `podinfo` is `Ready`, and every `podinfo` replica is ready.
