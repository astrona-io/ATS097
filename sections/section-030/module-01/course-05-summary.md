# Summary

Flux finds changes in Git by polling, and a webhook tells it about a change the moment it is pushed. This module connected the two with a `Receiver`.

## What you learned

source-controller fetches a `GitRepository` once per interval. A long interval keeps the load on the Git server low but delays every change; a short one does the opposite. A webhook is a request the Git server sends on every push, so the cluster fetches exactly when something changed. The interval stays as a safety net for lost webhooks.

A `Receiver` (`notification.toolkit.fluxcd.io/v1`) is served by notification-controller through the Service `webhook-receiver` in `flux-system`. Its `type` says what sender to expect and how to check requests, `events` filters event types, `secretRef` names a Secret with the key `token`, and `resources` lists the Flux objects to reconcile. When it is ready, `.status.webhookPath` holds `/hook/` followed by a SHA-256 hash of the token, the name and the namespace. The `github` and `generic-hmac` types also check an HMAC signature of the request body made with the token; the `generic` type checks only the path. Gitea sends GitHub-compatible webhooks, so a Receiver for Gitea uses the type `github`.

A Gitea push webhook calls the Receiver's full address and signs with the same token. Gitea inside the cluster reaches `webhook-receiver` directly, once its `ALLOWED_HOST_LIST` allows private addresses. Gitea's list of recent deliveries shows the response to every request, which is where a wrong token or a wrong address shows up. The key facts to remember are these:

- The webhook triggers; the interval is only the fallback.
- The webhook path depends on the token, the name and the namespace; read it again after any change.
- The token in the Git server and in the Receiver's Secret must be identical.
- The proof is a revision that holds the pushed commit within seconds.

<!-- astrona:playground:destroy -->
