# Summary

A GitOps repository describes everything the cluster runs, but a password cannot sit in it in plain text. This module showed why, what the options are, and how to recover when a Secret has already been committed.

## What you learned

A Kubernetes Secret protects nothing by itself. Values under `stringData` are plain text, and values under `data` are Base64-encoded, which anyone reverses with `base64 -d`. A Secret committed to Git is readable by everyone and every tool that can read the repository. Git keeps every old version, and every existing clone keeps its own copy, so deleting the file does not remove the value. A committed secret must always be rotated: replaced with a new value that makes the old one useless.

Teams keep secrets out of Git in plain text in two ways. SOPS and Sealed Secrets put the Secret in Git with its values encrypted. With SOPS, kustomize-controller decrypts the file before it applies it, using an age key, a PGP key or a key management service. With Sealed Secrets, a controller in the cluster decrypts a `SealedSecret` with its own key, which only that controller has. External Secrets Operator keeps no value in Git at all; an `ExternalSecret` names a value in an external secret store, and a controller copies it into a Secret.

Removing a committed Secret interacts with pruning. kustomize-controller lists every object it applied in `.status.inventory`, and with `prune: true` it deletes an object that has left Git. Running pods keep their values, but new pods cannot start until the Secret exists again. A Secret created with `kubectl` after the prune is not in the inventory, so Flux leaves it alone, but Git no longer describes it. The annotation `kustomize.toolkit.fluxcd.io/prune: disabled` keeps an object in the cluster when it leaves Git. The key facts to remember are these:

- Base64 is an encoding; anyone can reverse it without a key.
- A secret that reached Git is known; change the value, not only the file.
- With `prune: true`, a Secret that leaves Git is deleted from the cluster on the next reconciliation.
- Remove a file from `kustomization.yaml` in the same commit that deletes it, or the build fails.

<!-- astrona:playground:destroy -->
