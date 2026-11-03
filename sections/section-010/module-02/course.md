# Sealed Secrets With Flux

SOPS encrypts a file on your machine and Flux decrypts it with a key you give it. Sealed Secrets takes a different route: a controller inside the cluster creates the key pair itself, and anyone can encrypt a Secret with its public key, but only the controller can decrypt. The encrypted object is a new Kubernetes kind that Flux can apply from Git like any other manifest, with no decryption settings on the Kustomization at all.

Sealed Secrets is a controller and a command-line tool, `kubeseal`. The controller owns an RSA key pair. A `SealedSecret` is a custom resource that holds a Secret encrypted for one cluster; when the controller sees it, it decrypts it and creates the matching Kubernetes Secret.

Keep one sentence in mind: **a SealedSecret can only be opened by the cluster that owns the private key, so the key is the thing to back up.**

The module has four parts. **How Sealed Secrets Works** explains the key pair and the flow. **Install The Controller And Seal A Secret** installs it with a HelmRelease and seals a Secret. **Scopes And Names** explains what binds a sealed value to a name and a namespace. **The Controller Key: Rotation And Backup** covers renewal, backup and recovery, and compares the approach with SOPS.

## Learning objectives

After this module you can:

- Explain how the controller, the public certificate and the `SealedSecret` fit together.
- Install the controller with Flux and seal a Secret with `kubeseal`.
- Explain the strict, namespace-wide and cluster-wide scopes.
- Back up and restore the controller's sealing keys.
- Compare Sealed Secrets with SOPS for a given situation.

## Before you start

You need to know that a Kubernetes Secret holds Base64-encoded values and why that cannot go to Git. You need basic `kubectl` and Flux `HelmRelease` knowledge.

Your playground is a single-node `kind` cluster with Flux v2.9.6 (including helm-controller), the `GitRepository` `fleet`, the Flux `Kustomization` `podinfo`, and an in-cluster Gitea with the repository `gitops/fleet`. You install the controller yourself in the second part and the command-line tool `kubeseal` on your machine.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
