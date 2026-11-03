# Summary

A Receiver is reachable only where a route exists. This module followed a webhook request from its Service to the internet and added the layers that protect it.

## What you learned

The Service `webhook-receiver` in `flux-system` is of type `ClusterIP`. It listens on port 80 and forwards to port 9292 of the notification-controller pod. The NetworkPolicy `allow-webhooks` lets any source reach that port. A response code from the Receiver, even an error, shows that the Service, the port and the network path work.

A hosted Git service needs a public address. An Ingress, or a Gateway API route, publishes only the path prefix `/hook/` and sends it to the Service on port 80, and a `LoadBalancer` or `NodePort` Service would expose more than needed. The address a sender calls uses `https`, is made of the host plus the Receiver's `.status.webhookPath`, and keeps certificate verification on.

Protection comes in layers. The Receiver type checks a signature. The ingress controller can allow only the sender's source address ranges and limit the request rate. A NetworkPolicy limits who inside the cluster can call the Receiver. When delivery fails, a fixed order of checks finds the layer: the Git server's delivery list, then name resolution, certificate, Ingress, endpoints, NetworkPolicy and the controller log. The key facts to remember are these:

- Publish `/hook/` and nothing else.
- Use a signing type on any public address.
- Use one token per sender.
- Debug from the outside in and fix one layer at a time.

<!-- astrona:playground:destroy -->
