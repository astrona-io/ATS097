# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Secrets in Git

## Scenario

The team that runs `podinfo` committed its database password to the repository `gitops/fleet`, in the file `apps/podinfo/secret.yaml`. Everyone with read access to the repository has seen it. The password must leave Git and must change, and `podinfo` must keep running.

## Your task

1. Take the Secret `podinfo-db` out of Git: delete `apps/podinfo/secret.yaml` and stop the Kustomize file `apps/podinfo/kustomization.yaml` from listing it. Commit and push to `main`.
2. Give the Secret `podinfo-db` in the namespace `podinfo` the new password `rotated-db-password` (key `password`), without committing that value anywhere.
3. Make sure `podinfo` runs with all its replicas ready.

## Constraints

- Do not commit the new password to Git in any form, plain or Base64.
- Keep `prune: true` on the Flux `Kustomization` `podinfo`, and do not suspend it.
- Do not change the `GitRepository` `fleet` or point Flux at another repository.

## Done when

- No file on `main` in `gitops/fleet` holds a Secret or a password in plain text.
- The Secret `podinfo-db` holds the password `rotated-db-password`, and it is not in the inventory of the Flux `Kustomization` `podinfo`.
- The Flux `Kustomization` `podinfo` is `Ready`, and every `podinfo` replica is ready.
