# Overview: Keep Plain Secrets Out Of Git (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and Flux, deploys `podinfo` from Git, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6**, **SOPS 3.13.3** and **age 1.3.2**: the `flux`, `sops`, `age` and `age-keygen` tools are on your PATH, and the Flux controllers run in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, in the namespace `gitea`, behind the Service `gitea-http` on port `3000`. It uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`.
- The private repository **`gitops/fleet`**, branch `main`, with `apps/podinfo/`: a namespace, a Deployment, a Service, the Kustomize file `kustomization.yaml`, and **`secret.yaml`**, the Secret `podinfo-db` with `password: s3cr3t-in-git` in plain text.
- The **`GitRepository` `fleet`** (credentials in the Secret `fleet-auth`) and the **Flux `Kustomization` `podinfo`**, which applies `./apps/podinfo` with `prune: true`.
- **`podinfo`** in the namespace `podinfo`, 2 replicas. Its Deployment reads the key `password` of the Secret `podinfo-db` into `DB_PASSWORD`.
- A **`tester`** pod in the namespace `gitea`, with `curl` and `jq`.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` on your machine while a port-forward runs in a second terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

`gitea.localtest.me` resolves to `127.0.0.1`. If your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `show_flux` prints the Flux source and the Flux `Kustomization` with their ready state and revision. `show_inventory` lists every object the Flux `Kustomization` `podinfo` applied. `read_db_password` prints the password the Secret `podinfo-db` holds in the cluster.

```sh
show_flux() {
  flux get sources git
  flux get kustomizations
}
show_inventory() {
  kubectl -n flux-system get kustomization podinfo \
    -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
}
read_db_password() {
  kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
}
```

## Practice tasks

- Clone the repository and run `git log -p -- apps/podinfo/secret.yaml`. Find the commit that added the password.
- Change `stringData` to `data` in `secret.yaml` with the Base64 form of a new value (`printf 'value' | base64`), push, and decode it back with `read_db_password`. Note how little the change protects.
- Delete `podinfo-db` with `kubectl` and run `flux reconcile kustomization podinfo`. Predict whether Flux creates it again, and why.
- Remove `secret.yaml` from Git, push, and reconcile. Run `show_inventory` before and after, and then `kubectl -n podinfo rollout restart deployment/podinfo`. Watch the new pods with `kubectl -n podinfo get pods`.
- Create the Secret again with `kubectl` and a new value, and restart `podinfo`. Run `show_inventory` and explain why the Secret is not listed.
