# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** External secrets

## Scenario

The team will keep the API token of `podinfo` in a secret store and not in Git. The store is the operator's `fake` provider, which holds the value `eso-lab-value` under the key `/podinfo/api-token`.

## Your task

1. Install the External Secrets Operator with a `HelmRelease` named `external-secrets` in `flux-system`. Use the chart `external-secrets` from `https://charts.external-secrets.io`, the target namespace `external-secrets`, and install the CRDs.
2. In the namespace `podinfo`, create a `SecretStore` named `demo-store` with the `fake` provider holding `/podinfo/api-token` = `eso-lab-value`.
3. Create an `ExternalSecret` named `api-credentials` in `podinfo` with a refresh interval of `5m` or shorter. It reads `/podinfo/api-token` and produces a Secret `api-credentials` with the key `token`.

## Constraints

- Do not create the Secret `api-credentials` yourself.
- Do not set the refresh interval to `0`.

## Done when

- The `HelmRelease` `external-secrets` is `Ready` and a Deployment in `external-secrets` is available.
- The `ExternalSecret` `api-credentials` is `Ready`, and the Secret `api-credentials` holds `eso-lab-value` under `token` and is owned by the `ExternalSecret`.
- The `ExternalSecret` has a refresh interval between 1 second and 5 minutes.
