# Prerequisites

Before starting this capstone you should be able to:

- Find a plain or Base64-encoded credential in a repository and in Git history.
- Remove a committed Secret while Flux prunes, and create it again outside Git.
- Change a Deployment so an environment variable reads from a Secret instead of a ConfigMap.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6** (`flux` on your PATH, controllers in `flux-system`), plus `sops` and `age`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs. If the name does not resolve, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.
- The `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` (`./apps/podinfo`, `prune: true`), and `podinfo` running in the namespace `podinfo`.

## Working rules

- Everything is graded on the **final state** of the cluster and of `main` in `gitops/fleet`.
- `podinfo` must end with every replica ready. Plan the order of your changes so its pods can always start.
- Never commit a new value, in any form.
