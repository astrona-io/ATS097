# Section 030: Webhook Receivers

Flux pulls: source-controller asks Git for new commits on an interval. A short interval means many requests for nothing; a long one means a push waits minutes before it reaches the cluster. A webhook turns that around. The Git server sends a request the moment someone pushes, and Flux fetches at once.

In Flux, the object that accepts such a request is a `Receiver`. This section explains how a Receiver is protected and what it reconciles, connects the in-cluster Git server to one, and proves that a push reaches the cluster within seconds while the interval stays one hour.

## What you will learn

- Why polling on an interval trades speed against load, and what a webhook changes.
- The `Receiver` API: its types, the token Secret, the resources it reconciles, and the webhook path in its status.
- How the `github` and `generic-hmac` types check a signature, so only someone with the token can trigger a reconcile.
- Connecting a Gitea push webhook to a Receiver inside the cluster.
- Proving the result with a revision that changes within seconds of a push.

## The learning path

The section has one module. It has a landing page, two parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Reconcile On Push With A Receiver

The playground runs `podinfo` from `gitops/fleet`, and the `GitRepository` `fleet` polls only once an hour.

1. Polling, Webhooks And The Receiver API
2. Connecting A Git Server To A Receiver, followed by the lab **Reconcile On Every Push**
3. Summary

## Section capstone: Deliver A Rotated Secret Without Waiting

The team set up a Receiver and a Gitea webhook, but pushes still take an hour to arrive. The Receiver points at the wrong `GitRepository`, and the webhook signs with a different token. Fix both, then rotate the SOPS-encrypted database password in Git and prove it reaches `podinfo` within seconds. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-097-capstone-030
```
