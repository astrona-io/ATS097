# Credentials For Sources

A source that points at something private needs a credential, and Flux reads it from a Secret in the same namespace as the source. This part lists the Secret formats for Git, Helm and OCI sources and how to create them.

## Git over HTTPS and over SSH

For HTTPS, the Secret has the keys `username` and `password`, where the password is usually an access token. For SSH, it has `identity` (the private key) and `known_hosts`. Create them with the Flux CLI, which can also print the manifest:

<!-- astrona:playground:renew -->

```sh
flux create secret git gitea-auth --url=http://gitea-http.gitea.svc:3000/gitops/fleet.git \
  --username=gitops --password=TOKEN-VALUE -n flux-system --export
```

Read the printed manifest and see the keys. Remove `--export` to create the Secret in the cluster. Then reference it from the source:

```yaml
spec:
  url: http://gitea-http.gitea.svc:3000/gitops/fleet.git
  secretRef:
    name: gitea-auth
```

## Helm and OCI registries

A `HelmRepository` of the default type reads `username` and `password` from `spec.secretRef`. An OCI source, either a `HelmRepository` with `type: oci` or an `OCIRepository`, reads a Secret of type `kubernetes.io/dockerconfigjson` from `spec.secretRef`, and can instead use `spec.serviceAccountName` with an image pull secret on the service account. Create one with:

```sh
flux create secret oci registry-auth --url=registry.example.com --username=user --password=TOKEN-VALUE -n flux-system --export
```

## Keeping them out of Git

These Secrets are credentials, so do not commit them in plain form. Create them once by hand for the first bootstrap, or encrypt them with SOPS, or seal them, or, for cloud registries, use workload identity and set `spec.provider` on the source so no stored credential is needed.

You can now create the credentials for private sources. The next part uses a Secret to fill values into manifests.

## Common pitfalls

> [!WARNING]
> - **Creating the Secret in another namespace.** The source reads it only from its own namespace.
> - **Using a personal password instead of a token.** Tokens can be scoped and revoked.
> - **Leaving `--export` output in a file inside the repository.** The file holds the credential.
