# Receivers For Charts, Images And Artifacts

Git is one place where a change can start. Many teams publish the same desired state as an OCI artifact, a Helm chart or an object in a bucket, and their build system pushes it to a registry. A registry can send a webhook when that happens, and a Receiver can turn it into an immediate fetch, exactly as it does for a Git push.

An OCI artifact is a package stored in a container registry, addressed by a repository name and a tag or digest. In Flux, an `OCIRepository` makes source-controller pull such an artifact on an interval, and a `HelmRepository` does the same for charts.

Keep one sentence in mind: **a Receiver does not care where the change came from, it reconciles the objects you list.** The type decides how the request is checked, and the list decides what runs.

The module has four parts. **Sources Other Than Git** lists which objects a Receiver can reconcile. **Reconciling An OCIRepository On Push** pushes an artifact to a registry and shows the effect. **Registry Types And Filters** covers the registry webhook types and the CEL filter. **Many Resources, One Receiver** covers wildcards and operating several Receivers.

## Learning objectives

After this module you can:

- Name the Flux object kinds a Receiver can reconcile.
- Push an artifact with `flux push artifact` and have an `OCIRepository` pick it up through a Receiver.
- Choose the Receiver type for a registry that sends webhooks.
- Explain `resourceFilter` and what it is for.
- Select several resources with `matchLabels` and keep the list narrow.

## Before you start

You need to know what a Receiver is, how its type checks a request, and what an `OCIRepository` is. You need basic `kubectl`.

Your playground is a single-node `kind` cluster with Flux v2.9.6, the `GitRepository` `fleet`, the Flux `Kustomization` `podinfo`, an in-cluster Gitea, and the tools `flux`, `sops` and `age`. You deploy a small registry yourself in the second part.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
