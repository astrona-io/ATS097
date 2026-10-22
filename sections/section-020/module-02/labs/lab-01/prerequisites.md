# Prerequisites

Before starting this lab you should be able to:

- Read `flux get kustomizations` and `flux events` for a Flux `Kustomization`.
- Create a Kubernetes Secret from a file with `kubectl create secret generic --from-file`.
- Explain what `spec.decryption` does on a Flux `Kustomization`.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2 on your PATH, and the Flux controllers in `flux-system`.
- **Gitea** with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`), holding an encrypted Secret. The address `http://gitea.localtest.me:3000/gitops/fleet.git` works on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The team's age identity in the Secret `team-age-key` in the namespace `gitea`, key `age.agekey`.

## Working rules

- Everything is graded on the **final state** of the cluster and of `main` in `gitops/fleet`.
- You do not need to change anything in Git for this lab.
