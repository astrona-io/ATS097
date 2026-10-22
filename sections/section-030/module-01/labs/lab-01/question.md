# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Receivers

## Scenario

Releases of `podinfo` are pushed to `gitops/fleet`, and the team waits up to an hour for each one to reach the cluster, because the `GitRepository` `fleet` polls once an hour. The platform team will not poll more often. They want the Git server to tell the cluster about every push.

## Your task

1. Create a Secret `receiver-token` in `flux-system` with a random value under the key `token`.
2. Create a `Receiver` named `gitea-receiver` in `flux-system` that accepts GitHub-compatible webhooks signed with that token and reconciles the `GitRepository` `fleet`.
3. In Gitea, add an active webhook to `gitops/fleet` for push events that calls the Receiver's webhook path through the Service `webhook-receiver` and signs with the same token.

## Constraints

- Keep the interval of the `GitRepository` `fleet` at 30 minutes or more.
- Use a Receiver type that checks a signature.
- Do not expose anything outside the cluster; Gitea calls the Receiver inside the cluster.

## Done when

- The Receiver `gitea-receiver` is `Ready`, has the type `github`, and lists the `GitRepository` `fleet`.
- An active push webhook in `gitops/fleet` calls `http://webhook-receiver.flux-system.svc.cluster.local` plus the Receiver's webhook path.
- The `GitRepository` `fleet` still polls every 30 minutes or less often.
- A commit pushed to `main` is the revision of the `GitRepository` `fleet` within a minute.
