# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Sealed secrets

## Scenario

The `podinfo` application reads its database password from the Secret `podinfo-db` in the namespace `podinfo`. The Secret was created by hand and holds the value `created-outside-git`. The team wants the Secret to come from a `SealedSecret` instead, so the definition can live in Git, and the value must become `sealed-in-lab`.

## Your task

1. Install the Sealed Secrets controller with a `HelmRelease` named `sealed-secrets` in `flux-system`. Use the chart `sealed-secrets` from the repository `https://bitnami-labs.github.io/sealed-secrets`, the release name `sealed-secrets-controller` and the target namespace `flux-system`.
2. Install `kubeseal` on your machine.
3. Create a `SealedSecret` named `podinfo-db` in `podinfo` with the key `password` and the value `sealed-in-lab`, using the default strict scope.
4. Apply it and make the cluster Secret `podinfo-db` come from it.

## Constraints

- Do not use the cluster-wide or namespace-wide scope.
- Do not write the value `sealed-in-lab` into any file you apply to the cluster, except the plain Secret manifest that you give to `kubeseal`.

## Done when

- The `HelmRelease` `sealed-secrets` is `Ready` and the Deployment `sealed-secrets-controller` in `flux-system` is available.
- The `SealedSecret` `podinfo-db` exists in `podinfo`, and the Secret `podinfo-db` is owned by it and holds `sealed-in-lab`.
- The `SealedSecret` holds ciphertext under `spec.encryptedData.password` and carries no scope annotation.
