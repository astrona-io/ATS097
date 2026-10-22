# Reconcile On Push With A Receiver

Push a commit to `gitops/fleet` in the playground, and nothing happens for a long time. The `GitRepository` `fleet` checks Git once an hour, so source-controller only sees the commit at its next check. Making the interval shorter makes every check cost a request to the Git server, for every repository, all day long.

A webhook is a request that one system sends to another when an event happens. Git servers send one on every push if you configure it. Flux receives it with a `Receiver`: an object of notification-controller that exposes an address in the cluster and reconciles the objects it lists when a valid request arrives.

Keep one sentence in mind: **the interval is the safety net, the webhook is the trigger.** Flux still polls, but a push no longer has to wait for the next poll.

The module has two parts. **Polling, Webhooks And The Receiver API** explains the Receiver object, its types, its token and its webhook path. **Connecting A Git Server To A Receiver** creates a Receiver, adds a push webhook in Gitea and proves the effect with a push. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain the trade-off of the `GitRepository` interval and what a webhook adds.
- Name the parts of a `Receiver`: `type`, `events`, `secretRef` and `resources`.
- Explain how `.status.webhookPath` is formed and why it is hard to guess.
- Explain how the `github` and `generic-hmac` types check an HMAC signature, and why the `generic` type is weaker.
- Create a token Secret and a Receiver, and add a Gitea push webhook that calls it inside the cluster.
- Prove that a push reaches source-controller within seconds while the interval stays one hour.

## Before you start

You need basic Git and `kubectl`, and you need to know what a Flux `GitRepository` does: it makes source-controller fetch a branch on an interval and store each commit as an artifact, whose revision has the form `main@sha1:` followed by the commit hash.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Tools on your machine | `flux` 2.9.6, `sops` 3.13.3, `age` and `age-keygen` 1.3.2 |
| Flux v2.9.6 | The controllers in `flux-system`, including notification-controller and its Service `webhook-receiver` |
| `GitRepository` `fleet` | Fetches `gitops/fleet` with **`interval: 1h`** |
| Flux `Kustomization` `podinfo` | Applies `./apps/podinfo` with `prune: true` |
| `gitea` (namespace `gitea`) | An in-cluster Git server, allowed to send webhooks to addresses inside the cluster. The user `gitops` (password `gitops-password`, lab-only) owns `gitops/fleet` |
| `podinfo` (namespace `podinfo`) | The application |

The repository and the Gitea web interface answer at `http://gitea.localtest.me:3000` on your machine while a port-forward to Gitea runs in a second terminal.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
