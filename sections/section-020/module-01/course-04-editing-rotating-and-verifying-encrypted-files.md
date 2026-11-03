# Editing, Rotating And Verifying Encrypted Files

An encrypted file is not read-only. People change a password, add a key to a Secret, give a new team access, and replace a leaked key. SOPS has a command for each, and each one keeps the file consistent. This part shows the commands and explains the part of the file that makes a hand edit fail: the message authentication code.

## Change a value

The command `sops edit` decrypts the file into your editor and encrypts it again when you save. Run it with the identity available in the environment:

<!-- astrona:playground:renew -->

```sh
export SOPS_AGE_KEY_FILE=~/age-keys/age.agekey
sops edit secrets/podinfo/podinfo-db.yaml
```

When you save and close the editor, SOPS writes the file back with every changed value re-encrypted, and the rest of the file stays as it was. For a single value in a script, `sops set` changes one path without an editor, and `sops unset` removes one:

```sh
sops set secrets/podinfo/podinfo-db.yaml '["stringData"]["password"]' '"a-new-value"'
sops unset secrets/podinfo/podinfo-db.yaml '["stringData"]["old-key"]'
```

The path is written as a list of keys in JSON syntax, and the value is a JSON value, so a string has its own quotes inside the shell quotes.

To read one value without opening the whole file, use `--extract`:

```sh
sops --decrypt --extract '["stringData"]["password"]' secrets/podinfo/podinfo-db.yaml
```

## Change who can decrypt

Edit the recipients in `.sops.yaml`, then apply them to the existing file:

```sh
sops updatekeys -y secrets/podinfo/podinfo-db.yaml
```

`updatekeys` re-encrypts the data key for the recipients that the matching creation rule lists now. It does not change the encrypted values. Use `sops rotate` when you also want a new data key, which re-encrypts every value:

```sh
sops rotate --in-place secrets/podinfo/podinfo-db.yaml
```

`rotate` is the answer to a data key that may have been seen. It does not remove access from old versions of the file in Git, because anyone with an old recipient's key can still decrypt the old versions. A leaked key always needs a new value for the secret.

## The MAC and the sops block

Open an encrypted file and look at the `sops:` block at the end. It holds the encrypted data key for each recipient, the time of the last change, the SOPS version, and a field `mac`. The MAC is a message authentication code: a keyed hash of all the values in the file, itself stored encrypted. SOPS recomputes it at every decryption and compares.

That is why editing an encrypted value by hand in a text editor breaks the file. SOPS detects the difference and refuses to decrypt, with an error that names the MAC. The flag `--ignore-mac` exists for recovery, but use it only to read a damaged file and re-encrypt it, never to apply it.

## Review changes in Git

A normal `git diff` of an encrypted file shows changes in ciphertext, which tells a reviewer nothing. SOPS supports a diff driver that decrypts both sides for the diff, if the reviewer holds a key. Add a line to `.gitattributes` and tell Git what the driver is:

```sh
echo 'secrets/**/*.yaml diff=sopsdiffer' >> .gitattributes
git config diff.sopsdiffer.textconv "sops --decrypt"
```

The diff now shows the plain values for people with the key, and the file in the repository is still encrypted.

You can now change a value, change the recipients, create a new data key and explain why a hand edit fails. You know the commands, and you know that none of them can take back access that Git history already gave.

## Common pitfalls

> [!WARNING]
> - **Editing the encrypted text in a normal editor.** The MAC no longer matches and SOPS refuses to decrypt.
> - **Treating `updatekeys` as a revocation.** The removed recipient can still decrypt every older commit.
> - **Printing decrypted output into a file in Git.** `sops --decrypt secret.yaml > secret.yaml` writes the plain file over the encrypted one. Use `--in-place` only with `--encrypt`.
> - **Expecting the diff driver to work for everyone.** The `git config` setting is local to each clone, and the diff fails for people who do not hold a key.
