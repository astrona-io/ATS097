# Install The Controller And Seal A Secret

The fastest way to learn Sealed Secrets is to run the whole loop once: the controller is installed by Flux itself, a Secret is sealed on your machine, the sealed file goes through Git, and the application receives a Secret that never existed in the repository. This part does that with the `podinfo-db` Secret.

## Install the controller with Flux

The controller has a Helm chart. Save this as `sealed-secrets.yaml`. The name `sealed-secrets-controller` is the default name `kubeseal` looks for:

<!-- astrona:playground:renew -->

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: sealed-secrets
  namespace: flux-system
spec:
  interval: 1h
  url: https://bitnami-labs.github.io/sealed-secrets
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: sealed-secrets
  namespace: flux-system
spec:
  interval: 1h
  chart:
    spec:
      chart: sealed-secrets
      version: ">=2.0.0 <3.0.0"
      sourceRef:
        kind: HelmRepository
        name: sealed-secrets
  releaseName: sealed-secrets-controller
  targetNamespace: flux-system
  install:
    crds: Create
  upgrade:
    crds: CreateReplace
  values:
    fullnameOverride: sealed-secrets-controller
```

Apply it and wait for the release:

```sh
kubectl apply -f sealed-secrets.yaml
flux get helmreleases -n flux-system
kubectl -n flux-system get deploy sealed-secrets-controller
```

The release is ready when the chart is installed, and the controller deployment is available. In a real repository, this file is committed and Flux applies it, so the controller itself is also managed from Git.

## Install kubeseal and seal a Secret

Install `kubeseal` from the release page of the Sealed Secrets project, choosing a version that matches the controller's version. Then create a plain Secret as a file that stays outside Git. Save this as `podinfo-db-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-db
  namespace: podinfo
stringData:
  password: sealed-value-1
```

Seal it. The options tell `kubeseal` where the controller is:

```sh
kubeseal --controller-name=sealed-secrets-controller --controller-namespace=flux-system \
  --format yaml < podinfo-db-secret.yaml > podinfo-db-sealed.yaml
```

Open `podinfo-db-sealed.yaml`. It holds a `SealedSecret` whose `spec.encryptedData.password` is a long encrypted string. Delete the plain file or keep it out of the repository, and never commit it.

## Deliver it with Flux

Commit the sealed file into the folder that the Flux `Kustomization` `podinfo` applies, and list it in that folder's `kustomization.yaml`:

```sh
cp podinfo-db-sealed.yaml apps/podinfo/podinfo-db-sealed.yaml
git add apps/podinfo/podinfo-db-sealed.yaml && git commit -m "Add sealed podinfo-db" && git push
flux reconcile kustomization podinfo --with-source
kubectl -n podinfo get sealedsecret,secret podinfo-db
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
```

The `SealedSecret` and the Secret exist, and the Secret holds `sealed-value-1`. Git holds only the encrypted value.

## Seal offline

You can fetch the certificate once and seal without cluster access afterwards:

```sh
kubeseal --controller-name=sealed-secrets-controller --controller-namespace=flux-system --fetch-cert > sealed-secrets-cert.pem
kubeseal --cert sealed-secrets-cert.pem --format yaml < podinfo-db-secret.yaml > podinfo-db-sealed.yaml
```

The certificate is public, so you may commit it, which lets everyone on the team seal without reaching the cluster.

You can now install the controller, seal a Secret and deliver it with Flux. The next part explains why a sealed value fails when you change the name or the namespace.

## Common pitfalls

> [!WARNING]
> - **Sealing with the wrong controller name or namespace.** `kubeseal` cannot find the certificate. Pass `--controller-name` and `--controller-namespace`.
> - **Using a `kubeseal` far from the controller's version.** Keep the minor versions the same.
> - **Listing the file in no `kustomization.yaml`.** Flux does not apply it, and nothing happens.
