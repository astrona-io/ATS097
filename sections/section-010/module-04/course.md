# Secrets That Flux Itself Consumes

Most of this section is about secrets your applications use. Flux also reads Secrets for its own work: to clone a private Git repository, to pull a private chart or image, to fill values into manifests and Helm releases. This module covers those Secrets, how to create them, and how to keep them out of Git.

Flux can read a Secret in four ways. A source such as `GitRepository` points at a Secret with `spec.secretRef`. A `Kustomization` fills variables from a Secret with `postBuild.substituteFrom`. A `HelmRelease` reads chart values from a Secret with `valuesFrom`. A `Kustomization` or a kustomize file can generate a Secret from files with `secretGenerator`.

Keep one sentence in mind: **Flux reads Secrets that live in the cluster, so the question is always how each Secret got there without a plain copy in Git.**

The module has four parts. **Credentials For Sources** covers Git, Helm and OCI authentication Secrets. **Substitution From Secrets** covers `postBuild.substituteFrom`. **Helm Values From Secrets** covers `valuesFrom`. **Generated Secrets And Their Limits** covers `secretGenerator` and the hash suffix.

## Learning objectives

After this module you can:

- Create the Secret that a `GitRepository`, `HelmRepository` or `OCIRepository` needs.
- Fill manifest variables from a Secret with `postBuild.substituteFrom`.
- Pass a sensitive Helm value from a Secret with `valuesFrom`.
- Explain what `secretGenerator` does and why a generated Secret is not safe in Git.
- Choose how each of these Secrets reaches the cluster.

## Before you start

You need the playground's Flux `GitRepository` and `Kustomization`, and the idea that a Secret must not be committed in plain form. You need no key service.

Your playground is a single-node `kind` cluster with Flux v2.9.6, the `GitRepository` `fleet`, the Flux `Kustomization` `podinfo`, and an in-cluster Gitea with the repository `gitops/fleet`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
