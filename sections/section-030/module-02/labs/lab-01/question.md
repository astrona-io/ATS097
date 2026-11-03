# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Receivers

## Scenario

The Receiver `fleet-receiver` in `flux-system` reconciles the `GitRepository` `fleet` when a request reaches its path. It has the type `generic`, so any request to the path triggers a reconcile, and the path is the only protection. The token is in the Secret `receiver-token`. The platform team wants requests signed with the token.

## Your task

1. Read the Receiver's type and status.
2. Change the Receiver `fleet-receiver` so it validates an HMAC signature computed with the token.
3. Send a signed request from inside the cluster and confirm the `GitRepository` `fleet` is reconciled.

## Constraints

- Keep the name `fleet-receiver` and the Secret `receiver-token`.
- Do not use a type that skips the signature check.
- Do not change the interval of the `GitRepository` `fleet`.

## Done when

- The Receiver `fleet-receiver` has the type `generic-hmac`, is `Ready` and lists the `GitRepository` `fleet`.
- A request with a correct `X-Signature` header makes the Receiver reconcile `fleet`.
- A request without a signature, and one with a wrong signature, are rejected.
