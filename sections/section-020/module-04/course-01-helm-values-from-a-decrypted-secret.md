# Helm Values From A Decrypted Secret

The password a chart needs has to arrive as a Helm value, and the value must not be in Git in plain text. Flux gives a HelmRelease a way to read values from a Secret, and a Kustomization with decryption can create that Secret from an encrypted file. This part builds the chain with the `podinfo` chart and checks each link.

## How the chain works

Three objects take part. A Flux `Kustomization` with decryption turned on applies an encrypted Secret from Git. A `HelmRelease` lists that Secret in `spec.valuesFrom`. helm-controller reads the Secret, merges its content into the chart values and installs the chart. The Secret exists only in the cluster in plain form.

## Create the encrypted values Secret

Save a Secret as `secrets/podinfo-values.yaml` in your clone of the repository. The Secret holds a small values document under the key `values.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-values
  namespace: podinfo
stringData:
  values.yaml: |
    ui:
      message: "message from an encrypted Secret"
```

Encrypt it with your team recipient and the usual `encrypted_regex`, then commit it:

```sh
sops --encrypt --encrypted-regex '^(data|stringData)$' --age <RECIPIENT> --in-place secrets/podinfo-values.yaml
git add secrets/podinfo-values.yaml && git commit -m "Add encrypted podinfo values" && git push
```

## Read it in a HelmRelease

Save this as `helmrelease-podinfo.yaml`. The `HelmRepository` points at the OCI registry that publishes the chart:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo-charts
  namespace: podinfo
spec:
  type: oci
  interval: 1h
  url: oci://ghcr.io/stefanprodan/charts
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo-chart
  namespace: podinfo
spec:
  interval: 10m
  chart:
    spec:
      chart: podinfo
      version: "6.15.0"
      sourceRef:
        kind: HelmRepository
        name: podinfo-charts
  valuesFrom:
    - kind: Secret
      name: podinfo-values
      valuesKey: values.yaml
```

Apply it and read the status:

```sh
kubectl apply -f helmrelease-podinfo.yaml
flux get helmreleases -n podinfo
```

The release is ready once the chart is installed. `valuesKey` names the key in the Secret that holds the values document. Without it, the key `values.yaml` is the default.

## Put one value into a path

To put a single secret value into one path of the chart values, `targetPath` sets it without writing a values document. The Secret has the plain value, and the HelmRelease names where it goes:

```yaml
  valuesFrom:
    - kind: Secret
      name: podinfo-db
      valuesKey: password
      targetPath: redis.password
```

helm-controller sets the chart value `redis.password` to the content of the key `password`. This fits a Secret that other things also use, such as the `podinfo-db` Secret of the examples. List several `valuesFrom` entries and helm-controller merges them in order, so a later entry overrides an earlier one, and `spec.values` is merged last.

You can now feed a chart from an encrypted Secret and set single values by path. The next part asks which parts of a values file deserve encryption.

## Common pitfalls

> [!WARNING]
> - **Encrypting the file but not creating a Secret.** helm-controller cannot decrypt. It reads Secrets and ConfigMaps only.
> - **Applying the HelmRelease before the Secret exists.** The release fails until the Secret arrives. Order them, as the last part of the module shows.
> - **Forgetting `namespace` on the Secret.** The Secret must be in the namespace of the HelmRelease.
> - **Setting `targetPath` with dots in a key name.** Escape the dots or use a values document instead.
