# Reconciling An OCIRepository On Push

The shortest way to see a Receiver work on a non-Git source is to publish an artifact to a registry and watch the `OCIRepository` pick it up. You do not need a cloud registry for that. A small registry runs in the cluster, `flux push artifact` publishes into it, and a `curl` request stands in for the registry's webhook. This part sets all of it up and measures the delay.

## Deploy a registry

The Distribution registry is the reference implementation of the OCI registry. Save this as `registry.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: gitea
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2.8.3
          ports:
            - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: gitea
spec:
  selector:
    app: registry
  ports:
    - port: 5000
      targetPort: 5000
```

Apply it and wait for the pod:

```sh
kubectl apply -f registry.yaml
kubectl -n gitea rollout status deploy/registry
```

## Push an artifact and create the OCIRepository

Open a port-forward to the registry in a second terminal, then push the current folder as an artifact. The registry has no TLS, so tell the command so:

```sh
kubectl -n gitea port-forward svc/registry 5000:5000
```

```sh
flux push artifact oci://127.0.0.1:5000/podinfo-config:v1 \
  --path=./apps/podinfo \
  --source="local" \
  --revision="v1" \
  --insecure-registry
```

The command packs the folder into an OCI artifact and pushes it with the tag `v1`. Now tell Flux to fetch it. Save this as `ocirepository-podinfo.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo-config
  namespace: flux-system
spec:
  interval: 1h
  url: oci://registry.gitea.svc.cluster.local:5000/podinfo-config
  insecure: true
  ref:
    tag: v1
```

Apply it and read the revision:

```sh
kubectl apply -f ocirepository-podinfo.yaml
flux get sources oci
```

The source is ready and holds the artifact with the tag `v1`. The interval is one hour, so a new artifact under the same tag would not appear for up to an hour.

## Add the Receiver

Create a token and a `generic-hmac` Receiver for the source. Save this as `receiver-oci.yaml`:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: oci-receiver
  namespace: flux-system
spec:
  type: generic-hmac
  secretRef:
    name: receiver-token
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: OCIRepository
      name: podinfo-config
```

Apply it, together with the token Secret if you have none:

```sh
kubectl -n flux-system create secret generic receiver-token --from-literal=token="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
kubectl apply -f receiver-oci.yaml
```

Push a changed artifact under the same tag. Then send the signed request that a registry or a pipeline would send. Sign the body with an HMAC-SHA256 made with the token, send the hex value in the header `X-Signature: sha256=<hex>`, and `POST` it to `.status.webhookPath` through a port-forward to `webhook-receiver`. Read the source again:

```sh
flux get sources oci
```

The revision now shows the digest of the new artifact within seconds, while the interval is still one hour. The Receiver made source-controller pull at once, and the digest changed because the content did, even though the tag is the same.

You can now trigger an `OCIRepository` from a push and read the result as a digest. Real registries send their own webhook formats, which is the next topic.

## Common pitfalls

> [!WARNING]
> - **Using `latest` or a moving tag without a Receiver.** The source only notices the new content at the next interval.
> - **Forgetting `insecure: true` and `--insecure-registry` for a registry without TLS.** The fetch fails with a TLS error. Use TLS everywhere else.
> - **Reading the tag and not the digest.** The tag stays the same when content changes. The digest tells you what Flux holds.
