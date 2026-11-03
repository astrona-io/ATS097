# Debugging Delivery Layer By Layer

When a push does not reach the cluster, the fault lies in one layer: the name of the host, the certificate, the ingress, the Service, the network policy or the Receiver. Guessing wastes time, because each layer leaves a different sign. This part gives a fixed order of checks, from the outside in, with one command for each layer.

## From the outside in

Start where the sender starts. The Git server keeps a list of recent deliveries with the response of each one. Read it first: it tells you whether the request left, whether it got a connection, and which status the other side answered with. Then walk inward with the same request from your side:

<!-- astrona:playground:renew -->

```sh
curl -i -X POST "https://flux-webhook.example.com$HOOK_PATH"
```

Replace the host with yours. Read the result against this list:

1. The name does not resolve. The DNS record for the host is missing or wrong.
2. The connection works and the certificate is rejected. The certificate does not match the host, has expired, or was not issued.
3. The answer is a not-found page from the ingress controller. The Ingress path or host does not match. Compare them with the request.
4. The answer is a gateway error such as bad gateway. The Ingress found the Service and the Service has no ready endpoint, or points to the wrong port.
5. The answer comes from notification-controller, as an error that names the request. The Receiver rejected it, so look at the type, the signature and the events.

## Check the layers inside

Use `kubectl` to confirm the inner layers:

```sh
kubectl -n flux-system get ingress webhook-receiver
kubectl -n flux-system get endpoints webhook-receiver
kubectl -n flux-system get networkpolicy
kubectl -n flux-system logs deploy/notification-controller --tail=20
kubectl -n flux-system get receiver gitea-receiver
```

The Ingress shows its address and class. The endpoints list must hold the pod address on port 9292. The network policies show what is allowed. The controller log shows whether a request arrived at all, and the Receiver shows whether it is ready.

A fault in two layers at once is common, for example an Ingress with the wrong port number and a rotated token. Fix the outermost fault, send a test request again, and continue inward until the Receiver accepts a signed request.

## Prove the fix with a push

When the layers look right, push a commit and confirm the revision of the `GitRepository` changes within seconds. A successful test request shows the path works. Only a push shows that the sender's configuration is right too, because the sender builds its own request.

You now have an order of checks that finds the failing layer from the sign it leaves. The summary that follows collects what the module covered.

## Common pitfalls

> [!WARNING]
> - **Debugging the Receiver when the request never arrives.** Check the Git server's delivery list and the controller log first.
> - **Fixing two layers at once.** You cannot tell which change worked. Fix one and test.
> - **Testing with a request that differs from the sender's.** Send the same method, path and headers the sender uses.

## Your mission: Limit Who Can Call The Receiver

You can now do what the graded lab asks. It gives you a cluster with a fault or a missing piece, and you fix it on your own.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-097-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-097-lab-030-03
astrona start ats-097-playground-030-03
```
