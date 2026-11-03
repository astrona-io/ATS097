# Receiver Types And Request Validation

A Receiver accepts requests from the network, so the question that matters is how it decides that a request is real. The answer depends on the `type` of the Receiver. One type checks a signature of the request body, another compares a header with the token, and some check nothing beyond the secret path. Picking the wrong type leaves the address open to anyone who learns it.

A webhook request is an HTTP `POST` that a sender makes to a URL when an event happens. In Flux, notification-controller receives it and, if the request is valid, asks the listed objects to reconcile.

Keep one sentence in mind: **the type decides how a request proves who sent it.** Every other field of a Receiver only decides what happens after the request is accepted.

The module has four parts. **How Each Receiver Type Validates A Request** compares the types. **Sending A Signed Request By Hand** builds a valid and an invalid request with `curl` and `openssl` and shows which one reconciles. **Choosing Events And Resources** selects what a request triggers. **Receivers As Code** creates the objects with the `flux` command and keeps them in Git with an encrypted token.

## Learning objectives

After this module you can:

- Name the Receiver types and say how each one checks a request.
- Compute an HMAC signature with `openssl` and send a valid request to a `generic-hmac` Receiver.
- Explain why a request with a wrong signature is rejected and a request to the wrong path is not found.
- Use `events` and `resources` to limit what a Receiver reconciles.
- Create a Receiver with `flux create receiver` and keep its token in Git encrypted.

## Before you start

You need to know what a `Receiver` is, that it reads a token from the key `token` of a Secret, and that its `.status.webhookPath` depends on the token. You need basic `kubectl` and `curl`.

Your playground is a single-node `kind` cluster with Flux v2.9.6, the `GitRepository` `fleet` with a one-hour interval, the Flux `Kustomization` `podinfo`, an in-cluster Gitea with the repository `gitops/fleet`, and the tools `flux`, `sops` and `age`. There is no Receiver yet.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
