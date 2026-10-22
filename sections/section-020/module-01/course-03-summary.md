# Summary

A Secret can live in Git once only the right key can read its values. This module created that key and used SOPS to encrypt a Secret so that Git shows its structure but not its password.

## What you learned

age is a small encryption tool with a two-part key. The recipient starts with `age1`; it encrypts and is safe to share and to commit. The identity starts with `AGE-SECRET-KEY-1`; it decrypts and never goes to Git. `age-keygen -o` creates a key pair in a file, and `age-keygen -y` prints the recipient of an existing identity, so the identity file is the only thing to keep safe. A file can be encrypted for several recipients, and any one of their identities can then decrypt it.

SOPS encrypts the values of a YAML file and leaves the keys and the structure readable. It creates a data key for each file, encrypts the selected values with it, and stores the data key encrypted for every recipient in a `sops:` block, together with a message authentication code (MAC) that detects changes. The `.sops.yaml` file at the repository root holds `creation_rules`: `path_regex` picks the files, `encrypted_regex` picks the keys to encrypt, and `age` names the recipients. With `encrypted_regex: ^(data|stringData)$`, a Secret keeps its `kind`, name and namespace readable.

`sops --encrypt --in-place` encrypts a file using the first matching rule. `sops --decrypt` prints the plain file and needs the identity, which SOPS finds through `SOPS_AGE_KEY_FILE`. `sops <file>` opens the decrypted file in an editor and encrypts it again on save. The key facts to remember are these:

- The recipient encrypts and may be committed; the identity decrypts and never goes to Git.
- Encrypt before the first `git add`; a plain commit is permanent.
- Encrypt only `data` and `stringData`, so the object stays recognisable.
- Never edit encrypted text by hand; the MAC check then fails.

<!-- astrona:playground:destroy -->
