# The Key Types SOPS Supports

SOPS does not encrypt your values with the key you give it. It creates a random data key for each file, encrypts the values with it, and then encrypts the data key once for every key listed in the file's rule. The kind of key only decides how that last step is done. This part lists the kinds, so that you can choose the one that fits where your private key can safely live.

## One data key, many wrappers

Print the `sops:` block of any file you encrypted before. Each recipient has an entry that holds the data key encrypted for it. To decrypt, SOPS finds an entry it can open, recovers the data key, and decrypts the values with it. The values are encrypted once, whatever the number of keys.

This is why adding a key does not re-encrypt the values and why removing a key does not protect old files. The command `sops updatekeys` rewrites only the list of encrypted data keys.

## The key types

Each type has a field in a `creation_rules` entry of `.sops.yaml`:

| Type | Field | The private part lives in |
| --- | --- | --- |
| age | `age` | A file with an `AGE-SECRET-KEY-1` line |
| PGP | `pgp` | A GnuPG keyring or an exported key file |
| AWS KMS | `kms` | AWS; the field holds a key ARN |
| Google Cloud KMS | `gcp_kms` | Google Cloud; the field holds a key resource ID |
| Azure Key Vault | `azure_keyvault` | Azure; the field holds a key URL |
| HashiCorp Vault | `hc_vault_transit` | Vault's transit engine; the field holds a key URL |

For age and PGP, whoever holds the private key file can decrypt, from anywhere. For the four services, the private key never leaves the service. SOPS sends the encrypted data key to the service and receives the data key back, and the service checks that the caller is allowed and records the call.

## Which one to choose

Use a KMS when the cluster runs in a cloud that offers one and the identity of the controller can be tied to a role. You then keep no key file, you can revoke access with one policy change, and an audit log shows every decryption. Use age when there is no such service, for a local cluster, or for a small team. Use PGP only when you already manage PGP keys for people.

You can now list the key types and say where each one's private part lives. The next part shows how to give kustomize-controller the right to use the cloud kinds.

## Common pitfalls

> [!WARNING]
> - **Thinking the KMS encrypts the values.** It encrypts only the small data key. The values are encrypted by SOPS with the data key.
> - **Removing a key from `.sops.yaml` and expecting old files to change.** Only `sops updatekeys` rewrites a file.
> - **Choosing PGP for a new setup because it is familiar.** It needs a keyring and an unprotected key in the cluster.
