# Rotating Keys And Using A KMS

Keys do not last forever. A person who held the identity leaves the team, a laptop is lost, or the identity is pasted into the wrong chat. This part replaces the age key in the playground without a moment where Flux cannot decrypt, and then shows the alternative many teams choose: a key management service, where no identity file exists at all.

## Two keys during the change

A SOPS file can be encrypted for several recipients, and the Secret `sops-age` can hold several identities. Rotation uses both facts. For a short time, the file is encrypted for the old and the new recipient, and the cluster holds both identities, so whichever version of the file kustomize-controller sees, it can decrypt it. Then the old recipient and the old identity are removed.

```mermaid
flowchart TB
    A["old key only"] -->|"add new recipient"| B["file: old and new"]
    B -->|"add new identity"| C["cluster: old and new"]
    C -->|"remove old recipient"| D["file: new only"]
    D -->|"remove old identity"| E["new key only"]
```

The diagram shows the order: the cluster always holds an identity for every recipient the file in Git uses.

## Add the new key

Create the new key pair and add its identity to the cluster first, next to the old one. The playground's current identity is the one you copied into `$HOME/age-keys/team.agekey`:

<!-- astrona:playground:renew -->

```sh
age-keygen -o "$HOME/age-keys/new.agekey"
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$HOME/age-keys/team.agekey" \
  --from-file=new.agekey="$HOME/age-keys/new.agekey" \
  --dry-run=client -o yaml | kubectl apply -f -
```

The Secret `sops-age` now has two keys, `age.agekey` and `new.agekey`, and kustomize-controller reads both. Start the port-forward in a second terminal, then clone the repository and print both recipients:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
age-keygen -y "$HOME/age-keys/team.agekey"
age-keygen -y "$HOME/age-keys/new.agekey"
```

## Re-encrypt the data key

In `.sops.yaml`, change the `age:` line so it lists both recipients, the old one first, separated by a comma. Then let SOPS update the file. `sops updatekeys` decrypts the data key with an identity you hold and encrypts it again for exactly the recipients the matching rule now lists; the values themselves are not touched:

```sh
SOPS_AGE_KEY_FILE="$HOME/age-keys/team.agekey" sops updatekeys -y apps/podinfo/secret.yaml
git commit -am "Encrypt podinfo-db for the old and the new key"
git push
```

The `sops:` block now lists two age recipients. Next, edit `.sops.yaml` again so the `age:` line holds only the new recipient, and run `updatekeys` once more, this time with the new identity:

```sh
SOPS_AGE_KEY_FILE="$HOME/age-keys/new.agekey" sops updatekeys -y apps/podinfo/secret.yaml
SOPS_AGE_KEY_FILE="$HOME/age-keys/new.agekey" sops rotate --in-place apps/podinfo/secret.yaml
git commit -am "Encrypt podinfo-db for the new key only"
git push
```

`sops rotate` creates a new data key and encrypts the values again with it. That matters because the old identity could decrypt the old data key. After the push, run `flux reconcile kustomization podinfo --with-source` and check that the Flux `Kustomization` is `Ready`. Then remove the old identity from the cluster by creating `sops-age` again from `new.agekey` only.

## A rotated key does not protect old values

The new key protects new commits. It does nothing for the old commits in Git history: they are still encrypted for the old recipient, and anyone with the old identity can decrypt them. If the old identity leaked, every value it ever protected is known. A key rotation after a leak therefore always includes new values for the Secrets, encrypted with the new key. A key rotation for routine reasons, such as a person leaving, may keep the values if nothing suggests the identity was copied.

## No identity file: a key management service

A key management service (KMS) keeps the key inside a service and lets authorised callers encrypt and decrypt with it; the key itself never leaves the service. SOPS supports AWS KMS, Google Cloud KMS, Azure Key Vault and the HashiCorp Vault transit engine. In `.sops.yaml`, a creation rule then names the key instead of an age recipient, under `kms`, `gcp_kms`, `azure_keyvault` or `hc_vault_transit_uri`.

For Flux, the change is on the cluster side. With AWS KMS, Google Cloud KMS or Azure Key Vault, there is no `sops-age` Secret: you give the `kustomize-controller` service account in `flux-system` permission to decrypt with the key, through the cloud's workload identity feature. With Vault, the decryption Secret holds a Vault token under the key `sops.vault-token`. Rotating a key, or removing a person's access, then happens in the KMS, and no identity file can be pasted anywhere.

You can now rotate an age key without a gap, explain why a leak also needs new values, and describe how a KMS replaces the identity file. Together with encryption and decryption, that covers the whole life of a SOPS key in a Flux repository.

## Common pitfalls

> [!WARNING]
> - **Removing the old identity from the cluster before the file is re-encrypted.** kustomize-controller can no longer decrypt the version in Git, and the Flux `Kustomization` fails.
> - **Running `updatekeys` without an identity.** SOPS needs to decrypt the data key first; set `SOPS_AGE_KEY_FILE` to an identity the file is encrypted for.
> - **Keeping the leaked recipient "for safety".** Everyone with the leaked identity can then read every new value too.
> - **Rotating the key after a leak but keeping the values.** Git history still holds the old file, which the leaked identity decrypts.
