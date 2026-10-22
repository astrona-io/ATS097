# Prerequisites

Before starting this lab you should be able to:

- Write a `Receiver` with `type`, `events`, `secretRef` and `resources`.
- Read `.status.webhookPath` and build the full webhook address from it.
- Call the Gitea API with `curl`, and clone, commit and push with `git`.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- `flux` 2.9.6 on your PATH, and the Flux controllers in `flux-system`, including the Service `webhook-receiver`.
- **Gitea** with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`), allowed to send webhooks to addresses inside the cluster. The address `http://gitea.localtest.me:3000` works on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The `GitRepository` `fleet` with `interval: 1h`, and the Flux `Kustomization` `podinfo`.

## Working rules

- Everything is graded on the **final state**, and one check pushes its own commit to `main` and measures how fast source-controller fetches it.
- Leave your webhook and Receiver in place when you submit.
