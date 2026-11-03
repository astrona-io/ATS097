# Summary

Flux reads Secrets for its own work. This module covered the four ways it does so and how each Secret should reach the cluster.

## What you learned

Sources read credentials from a Secret in their own namespace through `spec.secretRef`: `username` and `password` for Git over HTTPS, `identity` and `known_hosts` for SSH, and a docker config for OCI. `flux create secret` builds them and `--export` prints the manifest. Cloud registries can use workload identity instead.

`postBuild.substituteFrom` replaces `${variable}` placeholders from a ConfigMap or Secret, with defaults and escaping, and puts the value into the applied object. `valuesFrom` merges chart values from a Secret in order, with `spec.values` last. `secretGenerator` creates a hashed Secret name but stores the input in Git in plain form. The key facts to remember are these:

- Source Secrets live in the source's namespace.
- Substituted values appear in the applied object.
- `valuesFrom` order decides which value wins.
- `secretGenerator` is not for real secrets.

<!-- astrona:playground:destroy -->
