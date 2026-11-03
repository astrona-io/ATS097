# Install The Operator And Read From A Store

This part installs the operator with Flux and reads a value from the `fake` provider. The fake provider keeps its values in the store resource, so it needs no account. It is for learning and tests only, because the values are visible in the manifest.

## Install the operator

Save this as `external-secrets.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: external-secrets
  namespace: flux-system
spec:
  interval: 1h
  url: https://charts.external-secrets.io
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: external-secrets
  namespace: flux-system
spec:
  interval: 1h
  chart:
    spec:
      chart: external-secrets
      sourceRef:
        kind: HelmRepository
        name: external-secrets
  targetNamespace: external-secrets
  install:
    createNamespace: true
    crds: Create
  upgrade:
    crds: CreateReplace
  values:
    installCRDs: true
```

Apply it and wait:

```sh
kubectl apply -f external-secrets.yaml
flux get helmreleases -n flux-system
kubectl -n external-secrets get deploy
```

Pin the chart to a version range in a real repository, as with any chart.

## Create a store and an ExternalSecret

Save this as `eso-demo.yaml`. The store holds one fake value, and the `ExternalSecret` reads it:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: demo-store
  namespace: podinfo
spec:
  provider:
    fake:
      data:
        - key: /podinfo/db-password
          value: store-value-1
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: podinfo-db
  namespace: podinfo
spec:
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: demo-store
  target:
    name: podinfo-db
  data:
    - secretKey: password
      remoteRef:
        key: /podinfo/db-password
```

Apply it and read the result:

```sh
kubectl apply -f eso-demo.yaml
kubectl -n podinfo get externalsecret podinfo-db
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
```

The `ExternalSecret` shows a ready status and the Secret holds `store-value-1`. Change the value in the store and wait for the refresh interval, and the Secret follows.

## Deliver it through Git

Move `eso-demo.yaml` into the folder that the Flux `Kustomization` `podinfo` applies, list it in `kustomization.yaml`, commit and push. Flux applies the two resources and the operator produces the Secret. Git holds the reference and, with a real provider, never the value.

You can now install the operator and read a value from a store. The next part covers how often it refreshes and what shape the Secret takes.

## Common pitfalls

> [!WARNING]
> - **Applying the `ExternalSecret` before the operator's CRDs exist.** The apply fails with no matching kind. Order them, as the last part shows.
> - **Using the fake provider outside tests.** The values are in plain text in the store resource.
> - **A wrong `remoteRef.key`.** The `ExternalSecret` reports a sync error and no Secret appears.
