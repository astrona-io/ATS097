# Prerequisites

Before starting this capstone you should be able to:

- Read a Receiver's status and spec, and list and change Gitea webhooks through the API or the web interface.
- Encrypt and edit a Secret with `sops`, using an identity from a Kubernetes Secret.
- Read `flux get sources git` and compare a revision with a commit hash.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2 on your PATH, and the Flux controllers in `flux-system`.
- **Gitea** with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000` works on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- `.sops.yaml` and an encrypted `apps/podinfo/secret.yaml` in Git. The Flux `Kustomization` `podinfo` decrypts them with the identity in the Secret `sops-age` in `flux-system`, which you may use to edit the file.
- The `GitRepository` `fleet` with `interval: 1h`, a Receiver `gitea-receiver`, its token in the Secret `receiver-token`, and a Gitea webhook.

## Working rules

- Everything is graded on the **final state**, and one check pushes its own commit to `main` and measures how fast source-controller fetches it.
- Do not use `flux reconcile` to deliver your change; the point is that the push delivers it.
