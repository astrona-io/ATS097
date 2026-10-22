# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Receivers

## Scenario

The team set up a Receiver and a Gitea webhook so that every push to `gitops/fleet` reaches the cluster at once. It never worked: changes still take up to an hour. Now the database password of `podinfo` must be rotated, and the team wants it in the cluster within seconds of the push.

## Your task

1. Find out why pushes do not reach the cluster. Look at the Receiver `gitea-receiver` and at the webhook's recent deliveries in Gitea. There is more than one fault.
2. Fix the Receiver and the webhook, so a signed push makes source-controller fetch the `GitRepository` `fleet` at once.
3. Rotate the password: `apps/podinfo/secret.yaml` must give the Secret `podinfo-db` (key `password`) the value `delivered-by-webhook`, encrypted with SOPS for the recipient in `.sops.yaml`. Push it, and let the webhook deliver it.

## Constraints

- Keep the interval of the `GitRepository` `fleet` at 30 minutes or more, and keep the Receiver type `github`.
- Do not commit `delivered-by-webhook` in plain text, and do not commit any age identity.
- Keep the decryption settings on the Flux `Kustomization` `podinfo`.

## Done when

- The Receiver `gitea-receiver` is `Ready` and lists the `GitRepository` `fleet`.
- The `GitRepository` `fleet` still polls every 30 minutes or less often.
- The Secret `podinfo-db` holds `delivered-by-webhook`, and `apps/podinfo/secret.yaml` on `main` is SOPS-encrypted without the plain value.
- No file on `main` contains an age identity.
- A commit pushed to `main` is the revision of the `GitRepository` `fleet` within a minute.
