# Section 020: SOPS With age

A Secret can go back into Git once its values are encrypted. SOPS encrypts only the values of a YAML file and leaves its structure readable, so a reviewer still sees which Secret changed, and age gives SOPS a small, simple key pair to encrypt with. Flux has SOPS built in: kustomize-controller decrypts the file just before it applies it.

This section first encrypts a Secret on your own machine, then gives the cluster the key it needs to decrypt, and ends with the hardest case: a key that leaked.

## What you will learn

- What an age recipient and an age identity are, and which one may be shared.
- How SOPS encrypts a file: a data key per file, encrypted for every recipient, and a message authentication code (MAC) that detects changes.
- Writing `.sops.yaml` creation rules with `path_regex` and `encrypted_regex`.
- Encrypting, reading and editing a Secret with `sops`.
- Giving kustomize-controller the age identity in the Secret `sops-age` and turning on `spec.decryption`.
- Rotating a leaked key with a new key pair, `sops updatekeys` and a new value.
- How a key management service (KMS) replaces the key file.

## The learning path

Work through the modules in order. Each module has a landing page, short parts, a graded lab right after the part it tests, and a summary. Each landing page starts the module's playground.

### 1. Encrypt Secrets With SOPS And age

The playground runs `podinfo` from `gitops/fleet`, with its Secret created outside Git. You create your own age key pair and encrypt a Secret for it.

1. age Keys And Recipients
2. Encrypting A Secret With SOPS, followed by the lab **Encrypt A Secret For Git**
3. Summary

### 2. Let Flux Decrypt Secrets In The Cluster

The playground's repository already holds an encrypted Secret, but Flux has no key to decrypt it, so `podinfo` cannot start.

1. Decryption In kustomize-controller, followed by the lab **Make Flux Decrypt Secrets**
2. Rotating Keys And Using A KMS
3. Summary

## Section capstone: Rotate A Leaked age Key

The age identity that Flux decrypts with was found in a public chat. Replace the key everywhere it is used: in `.sops.yaml`, in the encrypted file and in the cluster. Change the password it protected, because Git history still holds files the leaked key can decrypt. Work it after both module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-097-capstone-020
```
