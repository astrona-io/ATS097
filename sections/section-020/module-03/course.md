# SOPS With KMS And PGP

An age identity is a file, and a file can be copied, leaked or lost. Larger organisations prefer a key that never exists as a file: it stays inside a key management service (KMS), and each decryption is a call that the service can log, limit and revoke. Others already use PGP keys for people and want to keep them. SOPS supports all of these key types, and Flux can decrypt with each of them.

A key management service is a cloud or self-hosted service that holds encryption keys and performs encryption and decryption for authorised callers, without handing out the key. PGP is an older, widely used standard for public-key encryption; GnuPG (`gpg`) is the common tool for it.

Keep one sentence in mind: **SOPS always encrypts a data key for each key you list, so you can mix key types in one file and change them later without touching the values.**

The module has four parts. **The Key Types SOPS Supports** compares them. **Cloud KMS And Vault With Flux** shows the configuration for AWS, Google Cloud, Azure and Vault and how the cluster authenticates. **PGP End To End** encrypts with a PGP key and decrypts it in Flux. **Mixing And Migrating Keys** moves a file from one key type to another.

## Learning objectives

After this module you can:

- Name the SOPS key types and the `.sops.yaml` field of each.
- Explain how kustomize-controller authenticates to a KMS: workload identity or static credentials.
- Write a `.sops.yaml` rule for AWS KMS, Google Cloud KMS, Azure Key Vault and Vault transit.
- Generate a PGP key, encrypt a Secret for it and make Flux decrypt it.
- Move a file from age to a KMS key with `sops updatekeys` without changing the values.

## Before you start

You need to know how SOPS encrypts a file with a data key, how `.sops.yaml` creation rules work, and how a Flux `Kustomization` turns on decryption with `spec.decryption`. You need basic `kubectl` and a shell.

Your playground is a single-node `kind` cluster with Flux v2.9.6, SOPS 3.13.3, age 1.3.2, the `GitRepository` `fleet`, the Flux `Kustomization` `podinfo` without decryption, and an in-cluster Gitea with the repository `gitops/fleet`. The playground has no cloud account, so the cloud key types are reading only, and the PGP part is hands-on. You need `gpg` (GnuPG) on your machine for the PGP part.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
