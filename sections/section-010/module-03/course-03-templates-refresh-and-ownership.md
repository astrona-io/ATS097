# Templates, Refresh And Ownership

The default `ExternalSecret` copies each value into one key of a Secret. Real applications often need a different shape, a periodic refresh, and a clear rule for who owns the Secret. This part covers the settings that control those.

## Refresh interval

`spec.refreshInterval` sets how often the operator reads the store again. A value of `1h` is the default. A value of `0` reads the store once and never again. A short interval reaches changes sooner and puts more load on the store and its API limits. Read the status to see the last sync:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo get externalsecret podinfo-db -o jsonpath='{.status.refreshTime}{"\n"}'
```

## Templates

`spec.target.template` builds the Secret from the values, using Go templates. Use it to make a connection string, set the Secret type, or add labels:

```yaml
spec:
  target:
    name: podinfo-db
    template:
      type: Opaque
      data:
        url: "postgres://app:{{ .password }}@db.podinfo.svc:5432/app"
```

The key `.password` is the `secretKey` from `spec.data`. Apply the change and read the new key from the Secret.

## Creation and deletion

`spec.target.creationPolicy` controls who may create the Secret. `Owner` is the default: the operator creates it, owns it, and deletes it with the `ExternalSecret`. `Merge` writes into an existing Secret without owning it. `None` only updates a Secret that something else created.

`spec.target.deletionPolicy` controls what happens when the value disappears from the store. `Retain` is the default and keeps the Secret. `Delete` removes the Secret. `Merge` removes only the keys that came from the store.

## Many keys at once

`spec.dataFrom` reads every key under a path or a whole JSON secret, instead of listing each one in `spec.data`. Use it for a store entry that holds many fields.

You can now shape a Secret, set a refresh interval and pick the ownership rules. The last part ties the operator into the Flux ordering.

## Common pitfalls

> [!WARNING]
> - **A refresh interval of a few seconds against a cloud store.** The provider rate-limits the account.
> - **Using `Merge` without a reason.** The operator then shares a Secret with something else, and the two overwrite each other.
> - **Expecting `Delete` to be the default.** A removed store value leaves the old Secret in place unless the policy says otherwise.
