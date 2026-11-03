# Prerequisites

Before starting this lab you should be able to:

- Install the Sealed Secrets controller with a HelmRelease
- Replace a plain Secret with a SealedSecret without the controller refusing it
- Prove the cluster holds the real value while the SealedSecret holds only ciphertext

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- `flux` 2.9.6 on your PATH, and the Flux controllers in `flux-system`.
- **Gitea** with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000` works on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- A pod `tester` in the namespace `gitea` with `curl`.
- `sops` 3.13.3 and `age` 1.3.2 on your PATH.
- The `GitRepository` `fleet` and the Flux `Kustomization` `podinfo`.
- Access from the cluster to the internet, to pull the chart and its images.

## Working rules

- Everything is graded on the **final state** of the cluster and of the repository.
- Leave your changes in place when you submit.
