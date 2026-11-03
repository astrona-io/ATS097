# External Secrets Operator With Flux

Sealed Secrets and SOPS keep the secret inside Git in encrypted form. The External Secrets Operator keeps it out of Git completely. The value lives in an external secret store, such as a cloud secret manager or HashiCorp Vault, and the operator copies it into a Kubernetes Secret. Git holds only a description of which value to fetch.

The operator adds custom resources. A `SecretStore` says how to connect to a store. An `ExternalSecret` says which value to read and which Secret to create. Flux applies both from Git like any other manifest.

Keep one sentence in mind: **with External Secrets Operator, Git holds a reference to the secret and never the secret itself.**

The module has four parts. **How The External Secrets Operator Works** explains the resources and the sync loop. **Install The Operator And Read From A Store** installs it with a HelmRelease and uses the `fake` provider for a store you can run anywhere. **Templates, Refresh And Ownership** covers refresh intervals, templates and what happens on deletion. **Using It Next To Flux** covers ordering, health checks and the choice between the three tools.

## Learning objectives

After this module you can:

- Explain the `SecretStore`, `ClusterSecretStore` and `ExternalSecret` resources.
- Install the operator with Flux and create an `ExternalSecret` that produces a Secret.
- Set a refresh interval and a template, and explain the creation and deletion policies.
- Order the operator, its stores and the applications with Flux dependencies.
- Choose between SOPS, Sealed Secrets and the operator for a situation.

## Before you start

You need to know what a Kubernetes Secret is and how Flux applies a `HelmRelease`. You need no cloud account: the module uses the `fake` provider, which holds values in the store definition itself and is meant for tests only.

Your playground is a single-node `kind` cluster with Flux v2.9.6, the `GitRepository` `fleet`, the Flux `Kustomization` `podinfo`, and an in-cluster Gitea with the repository `gitops/fleet`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
