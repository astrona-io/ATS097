# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Secrets in Git

## Scenario

A security review of `gitops/fleet` found that `podinfo` gets its credentials straight from Git. The review lists three exposed values, in three different forms, all under `apps/podinfo/`: a database password, an API token and a mail server (SMTP) password. Every one of them must leave Git and change, and `podinfo` must keep running.

## Your task

1. Find every credential under `apps/podinfo/` in `gitops/fleet`. One is in a ConfigMap, and one is Base64-encoded.
2. Remove all three from Git. Settings that are not secret, such as the SMTP host, stay in Git.
3. Give the credentials new values, created outside Git, in the namespace `podinfo`:

   | Secret | Key | New value |
   | --- | --- | --- |
   | `podinfo-db` | `password` | `rotated-db-2026` |
   | `podinfo-api` | `token` | `rotated-api-2026` |
   | `podinfo-smtp` | `password` | `rotated-smtp-2026` |

4. Change the `podinfo` Deployment in Git so that `SMTP_PASSWORD` comes from the key `password` of the Secret `podinfo-smtp`.

## Constraints

- Do not commit any of the new values to Git, in plain text or Base64.
- Keep `prune: true` on the Flux `Kustomization` `podinfo`, and do not suspend it.
- The ConfigMap `podinfo-settings` stays in Git with `smtp-host`.

## Done when

- No file on `main` holds a Secret, a password or a token in plain text, and none holds a new value.
- The three Secrets hold their new values and are not in the inventory of the Flux `Kustomization` `podinfo`.
- `SMTP_PASSWORD` comes from the Secret `podinfo-smtp`, and the ConfigMap `podinfo-settings` in the cluster has no `smtp-password`.
- The Flux `Kustomization` `podinfo` is `Ready`, and every `podinfo` replica is ready.
