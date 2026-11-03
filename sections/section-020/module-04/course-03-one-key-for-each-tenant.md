# One Key For Each Tenant

In a shared cluster, several teams push to the same repository or to repositories the platform team reads. If one age key decrypts everything, then every Kustomization that can reference that key can apply, and so read, every team's secrets. The fix is one key for each tenant, a Kustomization that uses only its tenant's key, and a rule that keeps the keys apart. This part builds that with two tenants.

## Why a shared key is a problem

kustomize-controller decrypts a file with the key named in the Kustomization. The Secret that holds the key must be in the same namespace as the Kustomization. If every tenant's Kustomization used the same Secret in `flux-system`, any tenant who can create a Kustomization there could decrypt every file in a path they point at, including the other tenants' files. Separate keys make the file unreadable to the wrong tenant, even when it is in the same repository.

## Create two keys

Create an age key for each tenant and keep the recipients:

<!-- astrona:playground:renew -->

```sh
age-keygen -o tenant-a.agekey
age-keygen -o tenant-b.agekey
age-keygen -y tenant-a.agekey
age-keygen -y tenant-b.agekey
```

Create the tenant namespaces and store each identity in a Secret in its own namespace:

```sh
kubectl create namespace tenant-a
kubectl create namespace tenant-b
kubectl -n tenant-a create secret generic sops-age --from-file=age.agekey=tenant-a.agekey
kubectl -n tenant-b create secret generic sops-age --from-file=age.agekey=tenant-b.agekey
```

Write a rule per tenant in `.sops.yaml`, so that files under a tenant's folder are encrypted only for that tenant. Save this with the real recipients:

```yaml
creation_rules:
  - path_regex: tenants/tenant-a/.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    age: <RECIPIENT_TENANT_A>
  - path_regex: tenants/tenant-b/.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    age: <RECIPIENT_TENANT_B>
```

## One Kustomization per tenant

Each tenant gets a Kustomization in its own namespace that points at its own folder and its own key. Save this as `kustomization-tenant-a.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: tenant-a
  namespace: tenant-a
spec:
  interval: 10m
  path: ./tenants/tenant-a
  prune: true
  sourceRef:
    kind: GitRepository
    name: fleet
    namespace: flux-system
  serviceAccountName: tenant-a
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

`serviceAccountName` makes kustomize-controller apply the objects as that service account, so the tenant can only create what its role allows. A Kustomization in a tenant namespace that refers to a source in `flux-system` needs cross-namespace references to be allowed, which the platform team decides. If tenant B's file is placed under `tenants/tenant-a/`, tenant A's key cannot decrypt it, and the Kustomization reports a decryption failure instead of applying it.

You can now give each tenant a key and a Kustomization that uses only that key. The last part covers how to lay out the repository and apply things in order.

## Common pitfalls

> [!WARNING]
> - **One `sops-age` Secret in `flux-system` for all tenants.** Any tenant with a Kustomization there can decrypt every tenant's files.
> - **Letting tenants edit `.sops.yaml`.** A tenant could add a recipient it controls to its own files. That is acceptable. A tenant that can change another tenant's rule is not.
> - **Forgetting `serviceAccountName`.** The tenant's objects are applied with the controller's full permissions.
> - **Storing the tenant identity in Git.** Create it in the cluster only.
