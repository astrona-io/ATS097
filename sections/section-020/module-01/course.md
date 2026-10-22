# Encrypt Secrets With SOPS And age

A Secret in Git must be unreadable to everyone who can read the repository, and readable to the one thing that applies it. That is what encryption gives you: the file in Git holds encrypted text, and only a holder of the right key turns it back into the password.

SOPS is a command-line tool that encrypts the values in a YAML or JSON file and leaves the keys and the structure readable. age is a small encryption tool and key format. SOPS can encrypt for an age key, and that is the combination this module uses.

Keep one sentence in mind: **the recipient encrypts and may be shared, the identity decrypts and never goes to Git.** Every mistake that leaks an encrypted Secret comes back to that sentence.

The module has two parts. **age Keys And Recipients** creates an age key pair and shows what each half does. **Encrypting A Secret With SOPS** writes the creation rules in `.sops.yaml`, encrypts a Secret, reads what stays readable, and commits it. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Create an age key pair with `age-keygen` and print the recipient of an existing identity.
- Explain which half of the key pair may be shared and which must stay private.
- Explain how SOPS encrypts a file with a data key, encrypted once for every recipient.
- Write a `.sops.yaml` creation rule with `path_regex`, `encrypted_regex` and an `age` recipient.
- Encrypt a Kubernetes Secret with `sops --encrypt --in-place`, and say which parts stay readable.
- Decrypt and edit an encrypted file with `sops`, using `SOPS_AGE_KEY_FILE`.

## Before you start

You need Kubernetes basics (Secrets and `kubectl`), basic Git (`clone`, `commit`, `push`), and the idea of public and private keys: data encrypted with a public key can only be decrypted with the matching private key.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Tools on your machine | `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2 |
| Flux v2.9.6 | The Flux controllers in `flux-system`, with the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` (`./apps/podinfo`, `prune: true`) |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the private repository `gitops/fleet` |
| `podinfo` (namespace `podinfo`) | The application. It reads the key `password` of the Secret `podinfo-db`, which was created outside Git |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` on your machine while a port-forward to Gitea runs in a second terminal; the parts start it when they need it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
