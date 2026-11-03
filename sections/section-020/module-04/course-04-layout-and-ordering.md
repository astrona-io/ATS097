# Layout And Ordering

Once there are several tenants and a chart, the repository needs a layout that keeps files with the keys that fit them, and the cluster needs an order that creates a Secret before the HelmRelease that reads it. This part gives a layout that works and shows how `dependsOn` and health checks give the order.

## A layout that matches the rules

Group files by owner, and let the folder name be what the `path_regex` of a creation rule matches. A layout such as this one keeps each rule simple:

```text
fleet/
├── .sops.yaml
├── tenants/
│   ├── tenant-a/
│   │   ├── secrets/db.yaml        # encrypted for tenant A
│   │   └── helmrelease.yaml
│   └── tenant-b/
│       ├── secrets/db.yaml        # encrypted for tenant B
│       └── helmrelease.yaml
└── clusters/kind/                 # Flux Kustomizations
```

The folder `tenants/tenant-a` has one rule and one key. A new file placed there is encrypted for the right recipient without any extra flag, because the rule matches its path.

## Create the Secret before the release

A HelmRelease whose `valuesFrom` Secret does not exist yet fails to install. Put the Secret and the release in two Kustomizations and order them with `dependsOn`. Save this as `kustomizations-ordered.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: tenant-a-secrets
  namespace: tenant-a
spec:
  interval: 10m
  path: ./tenants/tenant-a/secrets
  prune: true
  sourceRef:
    kind: GitRepository
    name: fleet
    namespace: flux-system
  decryption:
    provider: sops
    secretRef:
      name: sops-age
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: tenant-a-apps
  namespace: tenant-a
spec:
  interval: 10m
  path: ./tenants/tenant-a
  prune: true
  dependsOn:
    - name: tenant-a-secrets
  sourceRef:
    kind: GitRepository
    name: fleet
    namespace: flux-system
```

Apply it and watch the order:

```sh
kubectl apply -f kustomizations-ordered.yaml
flux get kustomizations -n tenant-a
```

`tenant-a-apps` waits until `tenant-a-secrets` is ready, and `tenant-a-secrets` is ready only if decryption worked. A decryption failure therefore stops the apps from starting with a missing Secret, and the message points at the Kustomization that failed. Without the dependency, the HelmRelease would be retried and fail until the Secret appears.

A `HelmRelease` also has `dependsOn`, which orders releases against each other, but a Secret is not a release. The ordering between a Secret and a release comes from the Kustomizations that apply them.

## Keep the identities alive

Each tenant identity exists in the cluster and in a backup the tenant controls. If a tenant loses its identity, the platform team cannot recover its files. Agree who holds the backup, and test restoring one before the day it is needed.

You can now lay out encrypted files by owner and order Secrets before the releases that use them. The summary that follows closes the module.

## Common pitfalls

> [!WARNING]
> - **Putting the Secret and the HelmRelease in one Kustomization and hoping for order.** Flux applies them together and the release may fail first.
> - **Naming the folder differently from the rule.** The file is encrypted with the fallback rule or SOPS refuses.
> - **Using `prune: false` on the secrets Kustomization and then deleting a file.** The Secret stays in the cluster.
