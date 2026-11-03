# Overview: Receivers For Charts, Images And Artifacts (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and Flux, deploys `podinfo` from Git, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tools on your PATH:** `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2.
- **Flux v2.9.6** in `flux-system`, including notification-controller and its Service `webhook-receiver`.
- The **`GitRepository` `fleet`** and the **Flux `Kustomization` `podinfo`** (`./apps/podinfo`, `prune: true`).
- **Gitea** with the private repository **`gitops/fleet`** (lab-only user `gitops`, password `gitops-password`).
- **`podinfo`** in the namespace `podinfo`.

The repository and the Gitea web interface answer at `http://gitea.localtest.me:3000` on your machine while a port-forward runs in a second terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

`gitea.localtest.me` resolves to `127.0.0.1`. If your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Practice tasks

- Deploy the registry from the reading and push an artifact with `flux push artifact`.
- Create an `OCIRepository` with a one-hour interval and note its revision.
- Add a `generic-hmac` Receiver, push a changed artifact and send a signed request. Compare the digest before and after.
- Label two sources and select both with one `matchLabels` entry.
