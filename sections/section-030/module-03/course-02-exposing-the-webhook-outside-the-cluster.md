# Exposing The Webhook Outside The Cluster

A hosted Git service calls a public address, and the Service `webhook-receiver` has none. You must add a route from the internet to it. Several objects can do that, and they differ in what they expose. This part compares them and builds the one that exposes the least: an Ingress that routes only the path prefix `/hook/`.

## The options

A Service of type `LoadBalancer` gets an external address from the cloud and forwards every request to the Service. A Service of type `NodePort` opens a port on every node. Both expose the whole Service, which is all of notification-controller's webhook port. An Ingress, or a Gateway API route, sits in front of the Service and can choose which host and path to forward, so it can expose less.

The request still goes to the same Service, and the Receiver still checks it. The route only decides what reaches it. Prefer an Ingress or a Gateway API route, because they let you publish `/hook/` and nothing else.

## An Ingress for the webhook path

An ingress controller must be running in the cluster for an Ingress to do anything. The object only describes the rule. Save this as `ingress-webhook.yaml`, with your own host name:

<!-- astrona:playground:renew -->

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webhook-receiver
  namespace: flux-system
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - flux-webhook.example.com
      secretName: flux-webhook-tls
  rules:
    - host: flux-webhook.example.com
      http:
        paths:
          - path: /hook/
            pathType: Prefix
            backend:
              service:
                name: webhook-receiver
                port:
                  number: 80
```

The rule forwards requests for `flux-webhook.example.com` whose path starts with `/hook/` to the Service on port 80. A request for any other path gets the ingress controller's own not-found answer and never reaches notification-controller. The `tls` block names a Secret that holds the certificate and private key of the host. A certificate manager can create that Secret for you.

Apply it and read the result:

```sh
kubectl apply -f ingress-webhook.yaml
kubectl -n flux-system get ingress webhook-receiver
```

The Ingress shows an address once the ingress controller has picked it up. The webhook address in the Git server is then `https://flux-webhook.example.com` followed by the Receiver's `.status.webhookPath`. In the playground, no ingress controller or public name exists, so this object is a pattern to read and adapt, and the in-cluster address of the Service is what you use to test.

## Which address the Git server calls

The Git server needs the full address, with the scheme. Use `https` for anything on the internet. A hosted service refuses or warns about plain HTTP, and the signature does not hide the body in transit, so the traffic would be readable. Verify the certificate on the sender's side too. GitHub, GitLab and Gitea all have a setting to skip certificate verification, and it should stay off.

You can now publish the webhook path with an Ingress and name the address a Git server calls. A public route also invites unwanted callers, which the next part limits.

## Common pitfalls

> [!WARNING]
> - **Exposing the whole Service with a LoadBalancer.** It forwards every path. Route only `/hook/`.
> - **Applying an Ingress without an ingress controller.** The object exists and nothing serves it.
> - **Using `http` for a public webhook.** The body travels in clear text.
> - **Switching off certificate verification at the sender.** It removes the check that you are talking to your cluster.
