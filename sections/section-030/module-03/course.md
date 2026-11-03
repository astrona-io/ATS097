# Exposing The Receiver To The Internet

A Git server inside the cluster can call a Receiver by its Service name. Most Git servers do not run there. GitHub, GitLab and Bitbucket Cloud run on the internet, and their webhook requests need an address that they can reach from outside. Opening that address is the point where a Receiver becomes a service that strangers can also try to call, so the way you expose it matters as much as the Receiver itself.

A Service is a Kubernetes object that gives a stable address and port to a set of pods. An Ingress is an object that tells an ingress controller to route outside HTTP requests to a Service by host and path. A NetworkPolicy is an object that limits which pods may connect to which.

Keep one sentence in mind: **expose the webhook path and nothing else, and let the Receiver's own check be the last defence, not the only one.**

The module has four parts. **The Service And The Network Path Inside The Cluster** follows a request from a pod to notification-controller. **Exposing The Webhook Outside The Cluster** publishes only the path `/hook/`. **Limiting Who Can Call It** adds source limits and TLS. **Debugging Delivery Layer By Layer** finds which layer drops a request.

## Learning objectives

After this module you can:

- Name the Service, the port and the target port that carry a webhook to notification-controller.
- Explain what the NetworkPolicy `allow-webhooks` in `flux-system` allows.
- Write an Ingress that routes only the path prefix `/hook/` to the `webhook-receiver` Service.
- Explain the options to restrict callers: source address lists, TLS, and a signing Receiver type.
- Find the failing layer of a webhook delivery with `curl`, `kubectl get endpoints` and the controller log.

## Before you start

You need to know what a Receiver is and how its path forms. You need basic `kubectl` and to know what a Service and a pod label selector are.

Your playground is a single-node `kind` cluster with Flux v2.9.6, the `GitRepository` `fleet`, the Flux `Kustomization` `podinfo`, an in-cluster Gitea with the repository `gitops/fleet`, and a `tester` pod with `curl`. You create the Receiver yourself in the first part.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
