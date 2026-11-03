# Scopes And Names

A sealed value is bound to more than the cluster. By default, it is also bound to the name and the namespace of the Secret it came from, so someone who can read the `SealedSecret` cannot copy the value into another name or namespace to read it there. This part explains the three scopes that control that binding, and the errors that appear when the binding is not met.

## Strict, namespace-wide and cluster-wide

The scope is chosen when you seal. It decides what must stay the same for the controller to decrypt:

| Scope | What must match | Option |
| --- | --- | --- |
| strict (default) | The name and the namespace | none |
| namespace-wide | The namespace only; the name may change | `--scope namespace-wide` |
| cluster-wide | Nothing; the value decrypts anywhere in the cluster | `--scope cluster-wide` |

Seal the same Secret with each scope and compare. The `SealedSecret` records a scope annotation for the two wider scopes:

<!-- astrona:playground:renew -->

```sh
kubeseal --cert sealed-secrets-cert.pem --scope namespace-wide --format yaml < podinfo-db-secret.yaml | grep -A2 annotations
```

The output shows the annotation `sealedsecrets.bitnami.com/namespace-wide: "true"`. A cluster-wide value has `sealedsecrets.bitnami.com/cluster-wide: "true"`. A strict value has neither.

## What a strict value protects

With the strict scope, the name and the namespace are part of what is encrypted. If someone with write access to Git renames the `SealedSecret` or moves it to another namespace, the controller cannot decrypt it. The change fails instead of exposing the value in a place where the person could read the Secret. This matters in a cluster where people can read Secrets in some namespaces and not in others.

## Errors you will meet

When the controller cannot decrypt a `SealedSecret`, it records the reason in the status of the object and in an event. Read them:

```sh
kubectl -n podinfo describe sealedsecret podinfo-db
```

Two reasons are common. The value does not decrypt, because the name, namespace or scope no longer matches what was sealed, or because the cluster has a different key. And the controller refuses to take over a Secret that already exists and that it does not own: if a plain Secret named `podinfo-db` is in the namespace, the controller reports that the Secret exists and is not managed by it. Delete the plain Secret, or add the annotation `sealedsecrets.bitnami.com/managed: "true"` to it to let the controller adopt it.

## Choosing a scope

Use strict wherever you can. Use namespace-wide when a tool generates a different name for the Secret each time, for example a name with a suffix. Use cluster-wide only for values that every namespace is allowed to read, and treat that scope as a shared secret.

You can now pick a scope and read a decryption error. The last part covers the controller's key, which is the one thing you cannot lose.

## Common pitfalls

> [!WARNING]
> - **Renaming a strict SealedSecret.** The value no longer decrypts. Seal it again under the new name.
> - **Using cluster-wide by default.** Anyone who can create a `SealedSecret` in any namespace can read the value there.
> - **Leaving an old plain Secret in place.** The controller refuses to overwrite a Secret it does not own.
