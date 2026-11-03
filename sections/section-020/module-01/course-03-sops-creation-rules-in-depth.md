# SOPS Creation Rules In Depth

One recipient and one rule are enough for a first Secret. A real repository has several kinds of files, several teams and several clusters, and each needs its own choice of what to encrypt and for whom. The creation rules in `.sops.yaml` carry all of those choices, so a mistake in them is a mistake in every file SOPS encrypts afterwards. This part reads the rules closely, the way SOPS does.

## How SOPS picks a rule

SOPS looks at the path of the file you encrypt and walks the `creation_rules` list from the top. The first rule whose `path_regex` matches wins, and later rules are not read. A rule without a `path_regex` matches every file, so it belongs at the end of the list as the fallback. If no rule matches, SOPS stops with an error and encrypts nothing, and that is the safe result.

Save this as `.sops.yaml` in your clone, with your own recipients in place of the placeholders:

<!-- astrona:playground:renew -->

```yaml
creation_rules:
  - path_regex: secrets/team-b/.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    age: <RECIPIENT_TEAM_B>
  - path_regex: secrets/.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    age: <RECIPIENT_TEAM_A>
```

The specific rule for `secrets/team-b/` comes before the general rule for `secrets/`. If you swap them, the general rule matches first and team B's files are encrypted for team A. Check which rule applies by encrypting a file and reading the `age` entries in its `sops:` block:

```sh
sops --encrypt --in-place secrets/team-b/podinfo-db.yaml
grep recipient secrets/team-b/podinfo-db.yaml
```

The recipient listed must be the one for team B.

## Choosing which values to encrypt

Four settings select values, and a rule may use only one of the encrypted kinds and one of the unencrypted kinds:

| Setting | What it does |
| --- | --- |
| `encrypted_regex` | Encrypts only the keys whose name matches the regular expression |
| `encrypted_suffix` | Encrypts only the keys whose name ends with the suffix, for example `_secret` |
| `unencrypted_regex` | Encrypts everything except the keys that match |
| `unencrypted_suffix` | Encrypts everything except keys that end with the suffix; the default is `_unencrypted` |

For Kubernetes Secrets, `encrypted_regex: ^(data|stringData)$` is the usual choice, because it leaves `kind` and `metadata` readable so Flux and reviewers can see what the file is. For a values file used by a Helm chart, an `encrypted_suffix` or an `unencrypted_regex` fits better, because the names of the keys are chosen by the chart and you cannot rename them.

## Several recipients and key groups

The `age` field takes a comma-separated list. SOPS encrypts the data key once for each recipient, so any one of them can decrypt the file. That is how you give both a team key and a cluster key access to the same file.

When you need two different people to agree, use `key_groups`. Each group is a list of keys, and SOPS needs one key from a number of groups equal to `shamir_threshold`. Save this as the rule in `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/production/.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    shamir_threshold: 2
    key_groups:
      - age:
          - <RECIPIENT_PLATFORM_TEAM>
      - age:
          - <RECIPIENT_SECURITY_TEAM>
```

With threshold 2 and two groups, the file needs a key from the platform group and a key from the security group at the same time. Flux's kustomize-controller can decrypt such a file only if the identity Secret holds one key from each of those groups, so use key groups only where the cluster can hold both.

## Setting rules from the command line

Every field has a command-line flag, for example `--age` and `--encrypted-regex`. A flag overrides the file for that one command. The flag `--config` points SOPS at a configuration file in another place. Use the file in the repository for everything that is repeated, so that every team member and every pipeline encrypts the same way.

You can now read a creation rule the way SOPS does and choose the values, the recipients and the order. The next question is how to change a file once it is encrypted.

## Common pitfalls

> [!WARNING]
> - **Putting a broad rule above a specific one.** The first match wins, so the specific rule never runs.
> - **Encrypting every value of a Secret.** Without `encrypted_regex`, the file's `metadata.name` is encrypted too, and Flux cannot read the file's identity.
> - **Using key groups without checking the cluster.** If kustomize-controller holds only one of the keys, it cannot decrypt the file.
> - **Adding a recipient to `.sops.yaml` and expecting old files to change.** A rule affects new encryptions only. Old files need `sops updatekeys`.
