# Summary

A Receiver turns a request into a reconcile for any object in its list. This module applied that to sources other than Git and to registries.

## What you learned

The kinds a Receiver can reconcile include `GitRepository`, `OCIRepository`, `HelmRepository`, `HelmChart` and `Bucket`, and also Flux `Kustomization`, `HelmRelease` and the image automation kinds. For each object the Receiver sets the annotation `reconcile.fluxcd.io/requestedAt`, and the owning controller fetches or applies at once. Listing the source is enough, because the objects that use it follow its new revision.

An `OCIRepository` pulls an artifact by tag or digest. `flux push artifact` publishes into a registry, and a signed request to a `generic-hmac` Receiver makes the source fetch within seconds even when its interval is an hour. The digest, not the tag, shows which content Flux holds.

Registry webhooks have their own types. `dockerhub`, `quay` and `acr` rely on the secret path, `harbor` compares the `Authorization` header with the token, and `nexus` checks an HMAC. By default a Receiver refreshes every listed resource, and the field `resourceFilter` runs a CEL expression per resource to narrow that. Many sources are selected with `name: "*"` and `matchLabels`. The key facts to remember are these:

- The Receiver reconciles what it lists, whatever the source.
- Watch the digest, not the tag.
- Use one token per sender.
- Keep wildcards narrow.

<!-- astrona:playground:destroy -->
