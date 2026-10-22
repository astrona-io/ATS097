# Keep Plain Secrets Out Of Git

Open the repository that Flux reads, and you find a file called `secret.yaml`. Its last line is `password: s3cr3t-in-git`. Everyone who can clone the repository can read that password, and so can every tool that copies the repository: a continuous integration system, a backup, a fork on a laptop.

A Kubernetes Secret is an object that holds small sensitive values. Its `data` values are Base64-encoded, and its `stringData` values are not encoded at all. Base64 turns bytes into printable text so that they fit in YAML; anyone can turn the text back with `base64 -d`. It is an encoding, not encryption.

Keep one sentence in mind: **a secret that reached Git is a published secret, and the only real fix is a new value.** Removing the file is necessary, but Git keeps every old version, so the old value stays readable in history.

The module has three parts. **Why A Plain Secret Cannot Go To Git** reads the password from the repository, from Git history and from the cluster. **The Options For Secrets In GitOps** compares SOPS, Sealed Secrets and External Secrets Operator. **Removing A Secret That Was Committed** takes the Secret out of Git while `podinfo` keeps running and rotates the password. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain the difference between Base64 encoding and encryption, and decode a Secret's value.
- Find a secret in Git history with `git log -p`, and explain why deleting the file is not enough.
- Name three ways to handle secrets in GitOps and say where the key or the value lives in each.
- Predict what Flux does when a Secret it applied leaves Git while `prune: true` is set.
- Remove a committed Secret, recreate it outside Git with a new value, and restart the application.
- Check that a Secret no longer comes from Git, using the inventory of the Flux `Kustomization`.

## Before you start

You need Kubernetes basics (namespaces, Deployments, Secrets, `kubectl get` and `kubectl apply`) and basic Git (`clone`, `commit`, `push`, `log`). You also need to know what a Flux `GitRepository` and a Flux `Kustomization` do. The `GitRepository` makes Flux's source-controller fetch a repository. The Flux `Kustomization` makes kustomize-controller apply one folder of it, and with `prune: true` it also deletes what it applied before and is no longer in Git.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine and the Flux controllers in `flux-system` |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the private repository `gitops/fleet` |
| `GitRepository` `fleet` and Flux `Kustomization` `podinfo` | Flux fetches `gitops/fleet` and applies `./apps/podinfo` with `prune: true` |
| `podinfo` (namespace `podinfo`) | The application. Its Deployment reads the key `password` of the Secret `podinfo-db` into the environment variable `DB_PASSWORD` |
| `apps/podinfo/secret.yaml` | The Secret `podinfo-db`, committed with its password in plain text |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` on your machine while a port-forward to Gitea runs in a second terminal; the parts start it when they need it. The server uses plain HTTP and a password because it is a lab.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
