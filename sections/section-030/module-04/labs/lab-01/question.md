# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Receivers

## Scenario

Three sources carry the label `reconcile-on-push=true`: the `GitRepository` objects `fleet` and `fleet-copy`, and the `HelmRepository` `podinfo-charts`. A fourth source, the `GitRepository` `fleet-skip`, has no label and must not be reconciled by pushes. The token is in the Secret `receiver-token`.

## Your task

1. Create one `Receiver` named `push-receiver` in `flux-system` with the type `generic-hmac` and the Secret `receiver-token`.
2. Make it select the labeled `GitRepository` objects and the labeled `HelmRepository` objects with `matchLabels` and the name `*`, one entry for each kind.
3. Send a signed request from inside the cluster and confirm which sources were reconciled.

## Constraints

- Do not list the sources by name.
- Do not label `fleet-skip`.
- Do not change any interval.

## Done when

- The Receiver `push-receiver` is `Ready`, has the type `generic-hmac`, and has a `GitRepository` entry and a `HelmRepository` entry with the name `*` and the label `reconcile-on-push: "true"`.
- A signed request reconciles `fleet`, `fleet-copy` and `podinfo-charts`.
- The same request does not reconcile `fleet-skip`.
