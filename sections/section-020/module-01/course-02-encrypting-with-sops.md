# Encrypting A Secret With SOPS

You have a recipient, and you have a Secret that must go back into Git. If you encrypted the whole file with age, Git would hold one block of unreadable text: no reviewer could see which Secret changed, and Flux could not tell what kind of object it is. SOPS encrypts only the values and keeps the rest of the YAML readable. This part sets up SOPS for the repository, encrypts a Secret and commits it.

## How SOPS encrypts a file

SOPS creates a new random key for each file, called the data key, and encrypts each selected value with it. Then it encrypts the data key itself, once for every recipient, and stores those encrypted copies in a `sops:` block at the end of the file. It also stores a message authentication code (MAC), a checksum of all the values, so a change made by hand to the encrypted file is detected.

```mermaid
flowchart TB
    D["data key"] -->|"encrypts"| V["each value"]
    R["age recipient"] -->|"encrypts"| D
    D -->|"stored encrypted in"| S["sops: block"]
    V -->|"checked by"| M["MAC"]
```

The diagram shows the two layers: the data key encrypts the values, and the recipient encrypts the data key. To decrypt, SOPS first decrypts the data key with an identity, then the values with the data key.

## Write the creation rules

SOPS reads its settings for a repository from a file called `.sops.yaml` at the repository root. Its `creation_rules` list says which files use which recipients and which keys to encrypt. Start the port-forward in a second terminal and leave it running. If the name `gitea.localtest.me` does not resolve, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Clone the repository and print your recipient, which goes into the rule:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
age-keygen -y ~/age-keys/age.agekey
```

Save this as `.sops.yaml` in the `fleet` folder, with your own recipient in place of `<RECIPIENT>`:

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    age: <RECIPIENT>
```

`path_regex` is a regular expression for the file path: this rule applies to YAML files under `secrets/`. `encrypted_regex` selects the keys to encrypt; `^(data|stringData)$` encrypts everything under `data` and `stringData` and leaves `apiVersion`, `kind` and `metadata` readable. Without it, SOPS encrypts every value, including the Secret's name. `age` names the recipients, separated by commas when there are several.

## Encrypt a Secret

Write the Secret in plain text first, in the folder the rule covers. Save this as `secrets/podinfo/secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-db
  namespace: podinfo
type: Opaque
stringData:
  password: first-encrypted-password
```

Encrypt it in place. SOPS finds `.sops.yaml` in the current folder and uses the first rule whose `path_regex` matches:

```sh
sops --encrypt --in-place secrets/podinfo/secret.yaml
cat secrets/podinfo/secret.yaml
```

`apiVersion`, `kind`, `metadata` and the key name `password` are unchanged. The value is replaced by text of the form `ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]`: the encrypted bytes, the values the cipher needs, and the original type. At the end, the `sops:` block lists your recipient under `age`, with the data key encrypted for it, plus `lastmodified`, the `mac`, the `encrypted_regex` that was used and the SOPS `version`.

## Read and change it again

Decrypting needs the identity. SOPS finds it through the environment variable `SOPS_AGE_KEY_FILE`:

```sh
SOPS_AGE_KEY_FILE=~/age-keys/age.agekey sops --decrypt secrets/podinfo/secret.yaml
```

The output is the original YAML with `password: first-encrypted-password`. It is printed to your terminal only; the file stays encrypted. To change a value, run `sops secrets/podinfo/secret.yaml` with the same variable: SOPS decrypts the file into your editor and encrypts it again when you save. Never edit the `ENC[...]` text by hand, because the MAC then no longer matches and decryption fails.

The encrypted file is safe to commit. Commit both files and push:

```sh
git add .sops.yaml secrets/podinfo/secret.yaml
git commit -m "Add the encrypted podinfo-db Secret"
git push
```

Anyone who clones the repository now sees that a Secret named `podinfo-db` exists, but not its password. No Flux `Kustomization` applies the `secrets/` folder yet, so the cluster does not change.

You can now encrypt a Secret for a recipient so that only its values are hidden, read it back with the identity, and commit it safely. The open question is how kustomize-controller gets the identity it needs to decrypt the file in the cluster.

## Common pitfalls

> [!WARNING]
> - **Leaving out `encrypted_regex`.** SOPS then encrypts `kind` and `metadata.name` too, and Kubernetes cannot use the decrypted result as you expect. Encrypt only `data` and `stringData`.
> - **Running `sops` outside the repository.** SOPS looks for `.sops.yaml` from the current folder upwards; from elsewhere it finds no rule and asks for recipients.
> - **Committing the plain file first "to encrypt later".** That commit is permanent. Encrypt before the first `git add`.
> - **Editing `ENC[...]` text by hand.** The MAC no longer matches and the file cannot be decrypted. Always edit through `sops`.

## Your mission: Encrypt A Secret For Git

You can now write SOPS creation rules, encrypt a Secret so only its values are hidden, and commit it. The graded lab gives you a team recipient and asks you to commit `.sops.yaml` and an encrypted Secret that the team's identity can decrypt.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-097-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-097-lab-020-01
astrona start ats-097-playground-020-01
```
