# Substitution From Secrets

A Flux `Kustomization` can replace `${variable}` placeholders in manifests before applying them. The values can come from a Secret, so a manifest in Git holds the placeholder and the Secret holds the value. This is useful for a value that must appear inside a manifest field, such as a host name or an account id.

## How it works

Add `postBuild.substituteFrom` to the Kustomization. It lists ConfigMaps and Secrets in the Kustomization's namespace:

<!-- astrona:playground:renew -->

```yaml
spec:
  postBuild:
    substituteFrom:
      - kind: Secret
        name: cluster-secrets
        optional: false
```

The manifest uses the placeholder:

```yaml
env:
  - name: DB_HOST
    value: ${db_host}
```

Create the Secret with the key `db_host`:

```sh
kubectl -n flux-system create secret generic cluster-secrets --from-literal=db_host=db.internal
```

After the next reconcile the applied Deployment contains `db.internal`.

## Defaults and escaping

A placeholder can have a default, `${db_host:=localhost}`, used when the key is missing. Write `$${text}` to keep a literal `${text}` in the output. Variable names must match letters, digits and underscores.

## Limits

Substitution puts the value into the applied object. If you substitute a password into a ConfigMap or a Deployment environment variable, the password is readable there by anyone who can read that object. Substitute only values that are fine to appear in the manifest, and pass real credentials through a Secret that a pod references.

You can now fill manifests from a Secret and know where not to. The next part does the same for Helm values.

## Common pitfalls

> [!WARNING]
> - **Substituting a password into a ConfigMap or a pod environment variable.** The value is then visible in that object.
> - **A missing key with no default.** The placeholder is replaced by an empty string and the manifest may be wrong.
> - **`optional: false` on a Secret that does not exist yet.** The Kustomization fails until the Secret appears.
