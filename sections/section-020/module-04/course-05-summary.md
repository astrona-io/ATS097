# Summary

Helm and multi-tenancy do not change how SOPS works. They change who reads the decrypted result. This module followed an encrypted value into a chart and gave each tenant its own key.

## What you learned

helm-controller never decrypts. A Flux `Kustomization` with `spec.decryption.provider: sops` decrypts an encrypted Secret and applies it, and a `HelmRelease` reads that Secret through `spec.valuesFrom`, with `valuesKey` to select a key and `targetPath` to set one value. Helm merges the values in order: chart defaults, each `valuesFrom` entry, and last `spec.values`.

You can encrypt a whole values document in one Secret, split secret values from plain ones, or encrypt single keys by suffix. Splitting keeps the HelmRelease reviewable. In all cases the plain value ends up in a Secret in the cluster and in the Helm release data, so access to Secrets in the namespace is access to the values.

In a shared cluster, each tenant has its own age key. The identity is a Secret in the tenant's namespace, the tenant's Kustomization names it in `decryption.secretRef`, and `serviceAccountName` limits what the tenant can apply. A creation rule per tenant folder encrypts files for the right recipient. `dependsOn` makes the Kustomization that creates a Secret finish before the one that installs the chart. The key facts to remember are these:

- Only kustomize-controller decrypts.
- `spec.values` wins over `valuesFrom`.
- One key and one namespace for each tenant.
- Create the Secret before the release.

<!-- astrona:playground:destroy -->
