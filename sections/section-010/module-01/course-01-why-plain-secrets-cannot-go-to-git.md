# Why A Plain Secret Cannot Go To Git

A GitOps repository holds everything the cluster runs, so it is tempting to put the Secrets there too. Then Git is complete, and Flux creates the Secrets like any other object. This part shows what that costs. You read one password from three places: the file in Git, the history of Git, and the Secret in the cluster.

## Read the password from the repository

A Secret in Git is just a YAML file, so anyone who can clone the repository can read it. Start the port-forward to Gitea in a second terminal and leave it running. The address `gitea.localtest.me` points at your own machine, and the port-forward sends it to the Git server in the cluster. If `git clone` cannot resolve that name, add the line `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Back in your first terminal, clone the repository and print the Secret:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cat fleet/apps/podinfo/secret.yaml
```

The file is a Secret named `podinfo-db` in the namespace `podinfo`. Its `stringData` section holds the key `password` with the value `s3cr3t-in-git`, in plain text. `stringData` is a write-only convenience field: the API server converts each value to Base64 and stores it under `data`. Nothing in the file is protected.

## Base64 is not encryption

Some teams commit Secrets with `data` instead of `stringData`, because the values then look unreadable. Look at the Secret Flux created in the cluster, which stores the same value under `data`:

```sh
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}'; echo
```

The output is a short string of letters and digits that ends in `=`. That is Base64: a way to write any bytes with 64 printable characters. Base64 has no key, so anyone can reverse it:

```sh
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
```

The command prints `s3cr3t-in-git`. So a Secret with `data` in Git protects nothing either; it only takes one more command to read. Encryption is different, because reading the value needs a key that the reader does not have.

## Git keeps every old version

Now suppose someone notices the file and deletes it. The next commit no longer has the file, but every earlier commit still does. Ask Git for every change to the file, with its content:

```sh
git -C fleet log -p -- apps/podinfo/secret.yaml
```

Each commit that touched the file is listed with the lines it added and removed, and the line with the password is among them. Deleting the file adds one more commit; it does not change the older ones. Anyone who cloned the repository before the deletion also keeps their own full copy.

```mermaid
flowchart TB
    S["secret.yaml in Git"] -->|"clone"| L["laptops"]
    S -->|"mirror"| C["CI system"]
    S -->|"history"| H["every old commit"]
    S -->|"fetch"| F["source-controller"]
    F -->|"apply"| K["Secret in the cluster"]
```

The diagram shows that the cluster is only one of many places a committed secret reaches; deleting the file in Git reaches none of the others.

Rewriting history with tools that remove a file from every commit is possible, but it does not reach the copies that already exist. That is why the only safe answer to a committed secret is to treat the value as known and change it. This is called rotating the secret: you create a new value, give it to the application, and make the old one useless.

You now know that a Secret in Git is readable whether it uses `stringData` or `data`, and that removing it from Git does not remove the old value from the world. The open question is how to keep the desired state in Git without ever writing a value there in plain text.

## Common pitfalls

> [!WARNING]
> - **Treating Base64 as protection.** `base64 -d` reverses it with no key. A Secret with `data` in Git is as readable as one with `stringData`.
> - **Deleting the file and stopping there.** The value stays in every older commit and in every existing clone. Rotate it.
> - **Making the repository private and calling it safe.** Everyone with read access, and every tool that copies the repository, still reads the value.
> - **Pasting a decoded value into a ticket or a chat.** It is now in one more place. Decode only to check, and do not copy the result.
