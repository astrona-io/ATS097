# Prerequisites

Before starting this lab you should be able to:

- Clone a repository, change files, commit and push with `git`.
- Read a Kubernetes Secret and decode a Base64 value.
- Use `flux get`, `flux reconcile` and `kubectl` in a namespace.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6** (`flux` on your PATH, controllers in `flux-system`), plus `sops` and `age`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs. If the name does not resolve, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.
- The `GitRepository` `fleet` and the Flux `Kustomization` `podinfo`, which applies `./apps/podinfo` with `prune: true`, and `podinfo` running in the namespace `podinfo`.

## Working rules

- Everything is graded on the **final state** of the cluster and of the branch `main` in `gitops/fleet`.
- Change one thing at a time and check again with `flux get kustomizations` and `kubectl`.
- Never commit a new value in plain text, not even for a moment. Every commit stays in history.
