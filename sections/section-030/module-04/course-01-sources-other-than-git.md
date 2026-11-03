# Sources Other Than Git

A Receiver reconciles whatever objects its `resources` list names, and that list is not limited to a `GitRepository`. Knowing the whole list tells you which of your sources can react to a push instead of waiting for an interval. This part lists the kinds, shows what each one fetches, and explains what a Receiver does for each of them.

## The kinds a Receiver can reconcile

Source-controller owns the source kinds. Each has an interval and an artifact:

| Kind | What it fetches |
| --- | --- |
| `GitRepository` | A branch, tag or commit of a Git repository |
| `OCIRepository` | An OCI artifact from a container registry |
| `HelmRepository` | The index of a Helm chart repository (an HTTP or OCI repository) |
| `HelmChart` | One chart version from a source, built into an artifact |
| `Bucket` | The objects in a bucket of an S3-compatible service or a cloud storage service |

The Receiver can also list a Flux `Kustomization` or a `HelmRelease`, and the image automation kinds `ImageRepository`, `ImagePolicy` and `ImageUpdateAutomation`. Check the kinds your Flux version accepts with `kubectl explain receiver.spec.resources`.

## What the Receiver does for each

For every object in the list, the Receiver sets the annotation `reconcile.fluxcd.io/requestedAt` to the current time. Each controller treats a new value in that annotation as a request to reconcile now, so the effect is the same as `flux reconcile`. A source fetches again. If it finds a new revision, it stores a new artifact, and the Flux `Kustomization` or `HelmRelease` that uses it applies the change.

See the annotation on any source you have. Read the interval and the annotation of the `GitRepository`:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.interval}{"\n"}{.metadata.annotations}{"\n"}'
```

The interval is the long fallback. The annotations hold the time of the last reconcile request, if one was made. A Receiver adds one for every accepted request, so after the first webhook you see the annotation appear.

## Why use other sources

A build pipeline that produces a chart or an OCI artifact already has a registry. Pushing to the registry is a natural trigger. The Receiver lets the registry or the pipeline tell the cluster to fetch now, while the interval stays at an hour or more. The same reasons that apply to Git apply here: a short interval costs requests to the registry for nothing, and a long one delays every release.

You can now name the kinds a Receiver reconciles and say what it does to them. The next part makes it concrete with an `OCIRepository` and a registry you deploy.

## Common pitfalls

> [!WARNING]
> - **Assuming a Receiver only works with Git.** It works with every kind in its list.
> - **Listing a `HelmRelease` instead of its source.** The release only reacts when a new chart version arrives.
> - **Forgetting the `apiVersion` in an entry.** Each entry needs the full group and version of its kind.
