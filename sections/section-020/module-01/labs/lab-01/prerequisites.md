# Prerequisites

Before starting this lab you should be able to:

- Write a `.sops.yaml` creation rule with `path_regex`, `encrypted_regex` and an `age` recipient.
- Encrypt a file with `sops --encrypt --in-place` and decrypt it with `SOPS_AGE_KEY_FILE`.
- Clone, commit and push with `git`.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2 on your PATH, and the Flux controllers in `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs. If the name does not resolve, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.
- The team's age recipient in the ConfigMap `sops-recipient` in `flux-system`, key `recipient`.

## Working rules

- Everything is graded on the **final state** of `main` in `gitops/fleet`.
- You only need the recipient. You do not need, and are not given, the team's identity.
