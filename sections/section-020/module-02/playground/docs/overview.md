# Overview: Let Flux Decrypt Secrets In The Cluster (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and Flux, commits an encrypted Secret, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tools on your PATH:** `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2.
- **Gitea** with the private repository **`gitops/fleet`** (lab-only user `gitops`, password `gitops-password`):
  - `.sops.yaml`, a creation rule for every YAML file that encrypts `data` and `stringData` for the team recipient;
  - `apps/podinfo/secret.yaml`, the Secret `podinfo-db` with its password encrypted for that recipient, and listed in the Kustomize file `kustomization.yaml`.
- The Secret **`team-age-key`** in the namespace `gitea`, with the team's age identity under the key `age.agekey`. It stands in for the place a team keeps its identity, such as a password manager.
- **Flux v2.9.6** with the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` (`./apps/podinfo`, `prune: true`). It has **no decryption settings**, so it starts not `Ready`, and `podinfo` cannot start.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` on your machine while a port-forward runs in a second terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

`gitea.localtest.me` resolves to `127.0.0.1`. If your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `show_flux` prints the Flux source and the Flux `Kustomization` with their state. `read_db_password` prints the password the Secret `podinfo-db` holds in the cluster. `cluster_recipients` prints the recipient of every identity in the Secret `sops-age`.

```sh
show_flux() {
  flux get sources git
  flux get kustomizations
}
read_db_password() {
  kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
}
cluster_recipients() {
  kubectl -n flux-system get secret sops-age -o json \
    | jq -r '.data | to_entries[] | select(.key | endswith(".agekey")) | .value' \
    | while read -r encoded; do printf '%s' "$encoded" | base64 -d | age-keygen -y; done
}
```

## Practice tasks

- Before you fix anything, run `flux events --for Kustomization/podinfo` and write down, in your own words, what kustomize-controller reports.
- Create `sops-age` with the key name `age.key` instead of `age.agekey`, turn on decryption, and read the result. Then fix the key name.
- After decryption works, change the password in Git with `sops apps/podinfo/secret.yaml`, push, and watch `read_db_password` change after a reconcile.
- Rotate the key as the second part of the module shows, and run `cluster_recipients` at every step.
- Remove the old identity from `sops-age` before you re-encrypt, and watch what the Flux `Kustomization` reports. Then put it back.
