# Summary

A Receiver accepts requests from the network, and its type decides how a request proves where it came from. This module compared the types and built requests by hand to show the checks at work.

## What you learned

Every Receiver serves a secret path that comes from its token, its name and its namespace. The `generic` type checks only that path. The `generic-hmac`, `github`, `bitbucket` and `nexus` types check an HMAC of the request body made with the token, the `gitlab` type compares a header with the token, and the `harbor` type compares the `Authorization` header with it. The `dockerhub`, `quay` and `acr` types have only the path, because those senders cannot sign. A signature protects the Receiver even when the path appears in a log.

A valid request makes notification-controller annotate each object in `spec.resources` with a new `reconcile.fluxcd.io/requestedAt` value, and the owning controller reconciles it. You can build such a request yourself with `openssl` and `curl`: sign the exact body bytes, send the signature in the header the type expects, and the controller accepts or rejects it. The `events` field filters the event name for types where the sender announces one. The resources list names the objects to reconcile, and listing a source is enough, because the Kustomization follows its source.

A Receiver is an object like any other, so it belongs in Git. `flux create receiver --export` prints it as YAML. Its token Secret is encrypted with SOPS before it is committed, and the secret path is read again whenever the token changes. The key facts to remember are these:

- The type sets how a request is checked.
- A signature is stronger than a secret path alone.
- List the source, not its Kustomization.
- Keep the token encrypted in Git.

<!-- astrona:playground:destroy -->
