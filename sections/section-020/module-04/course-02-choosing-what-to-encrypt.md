# Choosing What To Encrypt

A values file mixes secret values with ordinary settings such as replica counts and image tags. If you encrypt the whole file, reviewers cannot read any of it and every change is a ciphertext diff. If you encrypt nothing, the passwords are public. This part compares the choices and gives a rule for picking one.

## Option 1: one Secret holds all the values

Put the full values document in a Secret under one key, as in the previous example, and encrypt that value. The advantage is that one file holds everything. The disadvantage is that `encrypted_regex: ^(data|stringData)$` encrypts the whole values document as a single block, so a review shows only that "something changed" inside it.

## Option 2: split secret and plain values

Keep ordinary settings in `spec.values` of the HelmRelease, in plain text, and put only the secret values in an encrypted Secret that `valuesFrom` reads. The HelmRelease stays reviewable, and the encrypted file is small:

<!-- astrona:playground:renew -->

```yaml
spec:
  values:
    replicaCount: 2
    ui:
      color: "#34577c"
  valuesFrom:
    - kind: Secret
      name: podinfo-db
      valuesKey: password
      targetPath: redis.password
```

Helm merges the values in this order: the chart's own defaults, each `valuesFrom` entry in the order listed, and `spec.values` last. If both define the same key, `spec.values` wins. Keep secret keys out of `spec.values` to avoid an accidental override.

## Option 3: encrypt only the secret keys of a values file

If the values must stay in one file, SOPS can encrypt only some keys, using a suffix. A rule with `encrypted_suffix: _secret` encrypts every key whose name ends with `_secret` and leaves the others. The names must then match the chart's keys, so this works only where you control the key names, for example in a values file you pass to your own chart.

## Choosing

Use option 2 for charts that you do not own: the chart decides the key names, and you only need a few passwords. Use option 1 for a short document of mostly secret values. Use option 3 for your own charts. In all three, the decrypted value is in a Kubernetes Secret in the cluster, and helm-controller stores the merged values in the release Secret that Helm keeps in the namespace, so anyone who may read Secrets in that namespace can read the values.

You can now pick what to encrypt for a chart. The module continues with a different question, which is who may decrypt.

## Common pitfalls

> [!WARNING]
> - **Putting a password in `spec.values` because it "is only for staging".** It is in Git in plain text.
> - **Expecting `spec.values` to be overridden by `valuesFrom`.** The inline values come last and win.
> - **Encrypting the entire HelmRelease.** Flux needs the readable kind and name, and the file is not a Secret.
