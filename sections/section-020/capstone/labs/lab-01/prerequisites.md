# Prerequisites

Before starting this capstone you should be able to:

- Create an age key pair and write `.sops.yaml` creation rules.
- Encrypt and edit a Secret with `sops`, and run `sops updatekeys`.
- Replace the identity in the Secret `sops-age` and turn on decryption on a Flux `Kustomization`.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2 on your PATH, and the Flux controllers in `flux-system`.
- **Gitea** with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- A working setup: `.sops.yaml` and an encrypted `apps/podinfo/secret.yaml` in Git, the current identity in the Secret `sops-age` in `flux-system`, and the Flux `Kustomization` `podinfo` decrypting with it.

## Working rules

- Everything is graded on the **final state** of the cluster and of `main` in `gitops/fleet`.
- Plan the order: the cluster must be able to decrypt what Git holds when Flux applies it.
