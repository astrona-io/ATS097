# Using It Next To Flux

The operator is a set of controllers and custom resources, so Flux has to install them in the right order, and the applications that need the Secret must wait for it. This part shows the dependency layout and compares the three tools.

## Order the layers

Use three Flux `Kustomization` objects. The first installs the operator, the second the stores and `ExternalSecret` objects, the third the applications:

<!-- astrona:playground:renew -->

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: secrets-config
  namespace: flux-system
spec:
  interval: 10m
  dependsOn:
    - name: external-secrets
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./infrastructure/secrets
  prune: true
  wait: true
```

`dependsOn` makes Flux wait until the `external-secrets` Kustomization is ready, so the CRDs exist before the `ExternalSecret` is applied. The application Kustomization depends on `secrets-config` in the same way.

## Health checks

`wait: true` waits for the applied resources to be ready. An `ExternalSecret` reports a `Ready` condition, so a Kustomization with `wait: true` stays not ready until the Secret has been created. An application that depends on it then starts only when the Secret exists.

## Credentials for the store

The operator needs a way to reach the store. Prefer workload identity, where the operator's service account maps to a cloud role, so no key is stored. If a key is unavoidable, deliver it as a SOPS-encrypted or sealed Secret, which is the one secret you keep in Git.

## Choosing between the three

Use SOPS when you want one repository to carry encrypted files, work with several key services, and encrypt any file. Use Sealed Secrets for simple single-cluster setups with Secrets only. Use the External Secrets Operator when a secret store already exists, when rotation must happen outside Git, or when several clusters and teams read the same values. Many setups combine them: SOPS for the store credentials, the operator for everything else.

You can now order the operator with Flux and choose between the tools. The summary closes the module.

## Common pitfalls

> [!WARNING]
> - **No `dependsOn` between the operator and the `ExternalSecret` Kustomization.** The first apply fails until the CRDs appear.
> - **Storing the store key as a plain Secret in Git.** Protect it with SOPS or use workload identity.
> - **Treating the operator as optional for startup.** Applications that need the Secret fail until it exists.

## Your mission: Read A Secret From A Store

You can now do what the graded lab asks. It gives you a cluster with a fault or a missing piece, and you fix it on your own.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-097-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-097-lab-010-03
astrona start ats-097-playground-010-03
```
