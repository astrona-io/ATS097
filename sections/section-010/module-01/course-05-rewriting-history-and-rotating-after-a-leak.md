# Rewriting History And Rotating After A Leak

Once a secret is in a pushed commit, many copies exist: the server, every clone, every fork, and every system that mirrored the repository. Rewriting history can remove the value from the copy you control, and it is worth doing, but it cannot recall the other copies. This part orders the response so that the step that protects you comes first, and shows how to rewrite history with `git filter-repo` afterwards.

## Rotate first

The order of the steps matters. The first action is to make the leaked value useless: change the password at its source, so that the credential in Git no longer opens anything. Create the new value, put it in the system that checks it (the database, the API provider), and deliver it to the cluster through the route you chose for secrets. Only the new value is safe.

After that, the old value in history is a dead credential. Rewriting history is hygiene that makes scanners quiet and stops the next reader from copying the old file. Do it second, because it takes time and because a rewrite can fail halfway while the secret stays valid.

## Remove the file from every commit

`git filter-repo` rewrites history. It is a separate tool, so install it first. Work in a fresh clone, because the tool changes every commit. Remove the Secret file from all commits:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git fleet-clean
cd fleet-clean
git filter-repo --invert-paths --path apps/podinfo/secret.yaml
```

`--invert-paths` keeps everything except the listed path. Every commit that touched the file is rewritten without it, so every commit hash after the first affected commit changes. `git filter-repo` also removes the `origin` remote on purpose, to stop an accidental push, so you add it again.

To keep the file but remove only the value, replace text instead. Put the string in a file named `expressions.txt`:

```text
literal:s3cr3t-in-git==>REMOVED
```

Run the rewrite with that file:

```sh
git filter-repo --replace-text expressions.txt
```

Check the result with the same search as before:

```sh
git log --oneline -S 's3cr3t-in-git' --all
```

The search prints nothing when the value is gone from every commit.

## Publish the rewritten history

Add the remote and force-push every branch and tag:

```sh
git remote add origin http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
git push --force --all
git push --force --tags
```

A force push replaces the history on the server. If the branch is protected, the server refuses until an administrator allows force pushes. Every other clone still holds the old history, and the next `git pull` in such a clone reports diverged history. Tell the team to clone again instead of merging, because a merge brings the old commits and the secret back.

Flux is one of those clones. source-controller fetches the branch by its new head, so it follows a force push without trouble. The commit hashes in the Flux revisions change, which is expected.

```mermaid
flowchart TB
    A["Leak found"] -->|"first"| B["Rotate the value"]
    B -->|"second"| C["Deliver new value without Git"]
    C -->|"third"| D["Rewrite history"]
    D -->|"fourth"| E["Force push and re-clone"]
```

The diagram shows the order of the response: the value changes before the history does.

You can now respond to a leak in the right order: rotate, deliver the new value by a safe route, rewrite history, and make every clone start again. The summary that follows collects what this module taught about secrets in Git.

## Common pitfalls

> [!WARNING]
> - **Rewriting history and skipping the rotation.** Forks, clones, caches and logs still hold the value.
> - **Running `filter-repo` in your only clone.** Work in a fresh clone, so a mistake costs nothing.
> - **Merging an old clone into the new history.** It restores the removed commits. Clone again.
> - **Forgetting that the remote is gone after `filter-repo`.** Add it back before you push.
