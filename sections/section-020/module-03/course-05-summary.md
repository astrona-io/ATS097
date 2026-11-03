# Summary

SOPS encrypts values with a random data key and encrypts that data key for each listed key. This module used that design to work with key types other than age.

## What you learned

The key type decides only where the private part lives. age and PGP keys are files. AWS KMS, Google Cloud KMS, Azure Key Vault and HashiCorp Vault transit keep the key inside a service, which receives the encrypted data key and returns the data key to authorised callers. The `.sops.yaml` fields are `age`, `pgp`, `kms`, `gcp_kms`, `azure_keyvault` and `hc_vault_transit`. Mixing types in one rule gives any one of them the right to decrypt.

Flux authenticates to a service with workload identity bound to the controller's service account, or to the service account named in `spec.decryption.serviceAccountName`, or with a static credential in the decryption Secret under `sops.aws-kms`, `sops.gcp-kms`, `sops.azure-kv` or `sops.vault-token`. A PGP key is stored as an exported private key under a key name that ends in `.asc`, and it must have no passphrase. The flow of create, list in a rule, encrypt, store and decrypt is the same for every type.

A move between key types adds the new key, runs `sops updatekeys`, checks decryption in the cluster, and only then removes the old key. The move does not remove access to old commits, so an exposed key still needs a new secret value. The key facts to remember are these:

- A KMS holds the key; SOPS holds the data.
- Prefer workload identity to static credentials.
- Add the new key before removing the old one.
- Old commits keep their old keys.

<!-- astrona:playground:destroy -->
