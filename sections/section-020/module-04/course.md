# SOPS With Helm Values And Tenants

Many applications are installed from Helm charts, and their configuration is a values file that often holds a password. Helm does not decrypt anything, and neither does the Flux controller that runs Helm. Several teams in one cluster add a second problem: each team must read its own secrets and not the secrets of the others. Both problems have a clear answer in how Flux splits the work between controllers.

A Helm chart is a package of Kubernetes manifests with templates. A HelmRelease is the Flux object that installs a chart and keeps it in the desired state; helm-controller reconciles it. A tenant is a team that owns a namespace in a shared cluster.

Keep one sentence in mind: **only kustomize-controller decrypts, so an encrypted value reaches Helm as a plain Secret that a Kustomization created.**

The module has four parts. **Helm Values From A Decrypted Secret** feeds a HelmRelease from a Secret. **Choosing What To Encrypt** compares an encrypted values file with a Secret. **One Key For Each Tenant** gives every team its own key. **Layout And Ordering** keeps the repository tidy and applies things in the right order.

## Learning objectives

After this module you can:

- Feed Helm values from a Secret with `valuesFrom`, using `valuesKey` and `targetPath`.
- Explain why helm-controller never decrypts and kustomize-controller does.
- Choose between encrypting a whole values file and encrypting only the secret values.
- Give each tenant its own age key, with `decryption.secretRef` in the tenant namespace.
- Order a Kustomization that creates a Secret before the HelmRelease that reads it.

## Before you start

You need to know how SOPS encrypts a Secret, how a Flux `Kustomization` turns on decryption, and what a `HelmRelease` is. You need basic `kubectl`.

Your playground is a single-node `kind` cluster with Flux v2.9.6, SOPS 3.13.3, age 1.3.2, the `GitRepository` `fleet`, the Flux `Kustomization` `podinfo`, and an in-cluster Gitea with the repository `gitops/fleet`. Check that helm-controller is installed with `kubectl -n flux-system get deploy helm-controller`. The playground has no tenants yet.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
