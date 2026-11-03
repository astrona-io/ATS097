# Summary

The External Secrets Operator keeps the secret value out of Git completely. This module installed it with Flux, read a value through a store, and ordered it with Flux dependencies.

## What you learned

A `SecretStore` or `ClusterSecretStore` describes how to reach a store. An `ExternalSecret` names a store, the values to read and the Secret to create. The operator reads the store at `spec.refreshInterval` and writes the Secret, so a change in the store reaches the cluster without a commit. Git holds only references.

`spec.target.template` shapes the Secret with Go templates. `creationPolicy` decides who owns the Secret, and `deletionPolicy` decides what happens when the value leaves the store. `dataFrom` reads many keys at once. The `fake` provider is for tests only.

Flux installs the operator first, the stores and `ExternalSecret` objects second and the applications last, using `dependsOn` and `wait: true`. The operator needs credentials to the store, best given by workload identity. The key facts to remember are these:

- Git holds a reference, not the value.
- The store is the source of truth and rotates on its own.
- Order the operator before its resources.
- Protect the store credentials.

<!-- astrona:playground:destroy -->
