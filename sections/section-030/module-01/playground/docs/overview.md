# Overview: Reconcile On Push With A Receiver (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and Flux, deploys `podinfo` from Git, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tools on your PATH:** `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2.
- **Flux v2.9.6** in `flux-system`, including notification-controller and its Service `webhook-receiver`.
- The **`GitRepository` `fleet`** with **`interval: 1h`**, and the **Flux `Kustomization` `podinfo`** (`./apps/podinfo`, `prune: true`).
- **Gitea** with the private repository **`gitops/fleet`** (lab-only user `gitops`, password `gitops-password`). Gitea may send webhooks to addresses inside the cluster (`ALLOWED_HOST_LIST=private`).
- **`podinfo`** in the namespace `podinfo`, with the Secret `podinfo-db` created outside Git.
- No Receiver and no webhook yet.

The repository and the Gitea web interface answer at `http://gitea.localtest.me:3000` on your machine while a port-forward runs in a second terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

`gitea.localtest.me` resolves to `127.0.0.1`. If your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `source_revision` prints the revision source-controller holds for `fleet`. `list_webhooks` prints the address and the events of every webhook of `gitops/fleet` (the port-forward must be running).

```sh
source_revision() {
  kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.revision}'; echo
}
list_webhooks() {
  curl -s -u gitops:gitops-password http://gitea.localtest.me:3000/api/v1/repos/gitops/fleet/hooks \
    | jq -r '.[] | "\(.id) \(.active) \(.config.url) \(.events | join(","))"'
}
```

## Practice tasks

- Push a commit before you create the Receiver, and run `source_revision` every few seconds. Note how long nothing changes.
- Create the Receiver and the webhook, push again, and time how long `source_revision` takes to show your commit.
- Change the token in `receiver-token` only, push, and read the webhook's recent deliveries in the Gitea web interface. Then read `.status.webhookPath` and explain why the address changed.
- Change the Receiver type to `generic` and push. Explain why it still works, and what protection you lost.
- Point the Receiver at the Flux `Kustomization` `podinfo` instead of the `GitRepository`, push, and explain what happens and what does not.
