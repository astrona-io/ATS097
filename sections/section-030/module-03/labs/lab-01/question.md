# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Receivers

## Scenario

`flux install` created a network policy `allow-webhooks` in `flux-system` that lets every pod and namespace send requests to notification-controller. The security team wants only the Git server, which runs in the namespace `gitea`, to reach the webhook receiver.

## Your task

1. Read the policies in `flux-system` and find the one that allows webhook traffic from everywhere.
2. Remove that policy.
3. Create a `NetworkPolicy` named `limit-webhook` in `flux-system` for the pods with the label `app=notification-controller`. It allows ingress only from the namespace `gitea`, on port `9292`.

## Constraints

- Do not delete or change other policies in `flux-system`.
- The Git server must still reach `http://webhook-receiver.flux-system.svc.cluster.local`.

## Done when

- The policy `allow-webhooks` no longer exists in `flux-system`.
- The policy `limit-webhook` selects `app=notification-controller`, has the policy type `Ingress`, and has one ingress rule from the namespace `gitea` on port `9292`.
- A request from the tester pod in `gitea` to the receiver Service gets an HTTP answer.
