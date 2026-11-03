# Mixing And Migrating Keys

A file can be encrypted for several keys of different types at once, and its keys can be changed later. These two facts make a safe move from one key type to another possible: add the new key, check that the new key works, and only then remove the old one. This part walks through that for a move from age to a KMS key, and it ends with the limits of the move.

## Several key types in one rule

A rule may list more than one type. Both entries below belong to the same rule:

<!-- astrona:playground:renew -->

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    kms: arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab
    age: <RECIPIENT>
```

SOPS encrypts the data key for the KMS key and for the age recipient. Any one of them can decrypt. During a migration, the KMS key serves the cluster and the age recipient serves people or a recovery copy.

## The migration in four steps

1. Add the new key to the rule, as above, and keep the old one.
2. Re-encrypt the data keys of the existing files with `sops updatekeys`, which reads the rule and rewrites the key list without touching the values:

```sh
sops updatekeys -y secrets/podinfo/podinfo-db.yaml
```

3. Give the cluster access to the new key (workload identity or a static credential), then commit and let Flux decrypt. Confirm that the Secret in the cluster has the right value.
4. Remove the old key from the rule, run `sops updatekeys` again, and remove the old identity Secret from the cluster once nothing uses it.

Do the steps in this order. If you remove the old key before the cluster can use the new one, Flux cannot decrypt and the Secret is not updated, though the existing Secret in the cluster stays as it was.

## What the migration does not do

A migration changes who can decrypt new versions of the files. It does not remove the old key's access to old versions in Git history, because those commits hold data keys encrypted for the old key. If the old key may have been exposed, replace the secret values too, with `sops rotate` for the data key and a new value at the source.

You can now plan a move between key types without a gap. The summary that follows collects the module.

## Common pitfalls

> [!WARNING]
> - **Removing the old key first.** Flux cannot decrypt the next push.
> - **Skipping `updatekeys` after changing the rule.** The files keep their old key list.
> - **Treating the migration as a revocation.** Old commits are still readable by the old key.

## Your mission: Add A Backup Recipient To An Encrypted File

You can now do what the graded lab asks. It gives you a cluster with a fault or a missing piece, and you fix it on your own.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-097-playground-020-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-020/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-097-lab-020-03
astrona start ats-097-playground-020-03
```
