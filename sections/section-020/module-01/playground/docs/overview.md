# Overview: Encrypt Secrets With SOPS And age (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and Flux, deploys `podinfo` from Git, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tools on your PATH:** `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2.
- **Flux v2.9.6** in `flux-system`, with the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo`, which applies `./apps/podinfo` with `prune: true`.
- **Gitea**, an in-cluster Git server, in the namespace `gitea`, with the private repository **`gitops/fleet`** (lab-only user `gitops`, password `gitops-password`). `apps/podinfo/` holds a namespace, a Deployment, a Service and the Kustomize file `kustomization.yaml`; there is no Secret in Git.
- **`podinfo`** in the namespace `podinfo`. It reads the key `password` of the Secret `podinfo-db`, which the bootstrap created outside Git with the value `created-outside-git`.
- No age key yet. You create your own.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` on your machine while a port-forward runs in a second terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

`gitea.localtest.me` resolves to `127.0.0.1`. If your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal, after you have created `~/age-keys/age.agekey`. `my_recipient` prints the recipient of your identity. `sops_read` decrypts a file with your identity and prints it, without changing the file.

```sh
my_recipient() {
  age-keygen -y ~/age-keys/age.agekey
}
sops_read() {
  SOPS_AGE_KEY_FILE=~/age-keys/age.agekey sops --decrypt "$1"
}
```

## Practice tasks

- Create a second key pair and encrypt a Secret for both recipients (`age: <first>,<second>`). Decrypt it with each identity on its own.
- Encrypt the same Secret twice and compare the `ENC[...]` text. Explain why it differs although the value is the same.
- Remove `encrypted_regex` from `.sops.yaml`, encrypt a new Secret, and look at what happened to `metadata.name`.
- Change one character inside an `ENC[...]` value by hand and try `sops_read` on it. Read the error about the MAC.
- Run `git log -p` on your encrypted file and confirm that no commit holds the password in plain text.
