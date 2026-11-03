# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Flux secrets

## Scenario

The repository holds the ConfigMap `banner` with the text `${banner_text}`. The Flux `Kustomization` `podinfo` applies it as it is, so the ConfigMap shows the placeholder. The text must come from a Secret in the cluster and must not be written into Git.

## Your task

1. Create a Secret `cluster-secrets` in `flux-system` with the key `banner_text` and the value `hello-from-secret`.
2. Change the Flux `Kustomization` `podinfo` so it fills variables from that Secret.
3. Reconcile and read the ConfigMap `banner` in `podinfo`.

## Constraints

- Do not edit `apps/podinfo/banner.yaml` in Git; it keeps the placeholder.
- Keep `prune: true` on the Flux `Kustomization` `podinfo`.

## Done when

- The Flux `Kustomization` `podinfo` lists the Secret `cluster-secrets` in `spec.postBuild.substituteFrom`.
- The ConfigMap `banner` in `podinfo` has `text` equal to `hello-from-secret`.
- `apps/podinfo/banner.yaml` on `main` still contains `${banner_text}`.
