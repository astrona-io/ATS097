# Helm Values From Secrets

A `HelmRelease` can take chart values from ConfigMaps and Secrets through `spec.valuesFrom`, merged in order with `spec.values`. This keeps a sensitive value out of the HelmRelease manifest in Git.

## A whole values file from a Secret

By default, `valuesFrom` reads the key `values.yaml` of the referenced object:

<!-- astrona:playground:renew -->

```yaml
spec:
  valuesFrom:
    - kind: Secret
      name: podinfo-values
```

The Secret holds a values file:

```sh
kubectl -n podinfo create secret generic podinfo-values --from-file=values.yaml=values.yaml
```

## One value at a time

`valuesKey` picks another key, and `targetPath` sets the chart value that receives it:

```yaml
spec:
  valuesFrom:
    - kind: Secret
      name: podinfo-db
      valuesKey: password
      targetPath: config.dbPassword
```

Order matters. Later entries win over earlier ones, and `spec.values` is applied last, so it overrides all of them.

## What the release records

Helm stores the rendered values in its release Secret, so the value is also present there. Anyone who can read Secrets in the namespace can read it, which is the same set of people who could read the original Secret.

## Reaching the cluster safely

The Secret that `valuesFrom` reads still has to arrive without a plain copy in Git. Encrypt it with SOPS, seal it, or let the External Secrets Operator produce it.

You can now pass a sensitive Helm value from a Secret. The last part covers generated Secrets.

## Common pitfalls

> [!WARNING]
> - **Reading the Secret from another namespace.** `valuesFrom` uses the namespace of the HelmRelease.
> - **Wrong order.** A value in `spec.values` overrides the same key from `valuesFrom`.
> - **A missing `targetPath` with `valuesKey`.** The value is parsed as a whole values document and fails.
