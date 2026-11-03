# Finding Secrets Before They Are Committed

Removing a secret from Git after the fact always costs a rotation, so the cheapest fix is to stop the commit. Two kinds of check help: a scan of the repository that finds secrets already there, and a check that runs before each commit and refuses a new one. This part uses the repository of the playground to show what a scan finds, what Git itself can search for, and how to turn the scan into a habit.

## Search history with Git alone

Git can search every commit for a string, with no extra tool. The option `-S` lists the commits that added or removed a given string. Clone the repository and search for the password that you know:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
git log --oneline -S 's3cr3t-in-git' --all
```

The output lists each commit where the number of occurrences of the string changed, which includes the commit that added the Secret and the one that removed it. This search needs you to know the value. It cannot find a secret you do not know about, so it is a tool for scoping a leak after you found one.

To find a secret you do not know about, search for the shape of a secret. Every Kubernetes Secret has `kind: Secret`:

```sh
git grep -n 'kind: Secret' $(git rev-list --all) -- '*.yaml' | head
```

The command lists the commit, the file and the line for each match, in every commit. A hit in an encrypted file is fine, because its values are ciphertext. A hit with plain `password:` values is a leak.

## Scan with a secret scanner

A secret scanner knows the formats of many credentials, such as cloud keys and tokens, and high-entropy strings that look random. gitleaks is an open-source scanner that reads the Git history. Install a release of gitleaks 8.x on your machine, then scan the whole history and the current files:

```sh
gitleaks git --verbose .
gitleaks dir .
```

`gitleaks git` reads every commit; `gitleaks dir` reads the files in the working directory. Each finding names the file, the line, the commit and the rule that matched. The scan exits with a non-zero code when it finds something, which makes it usable in a pipeline.

A scanner reports false positives, such as an example token in a document. Record each reviewed false positive in a `.gitleaksignore` file with its fingerprint, so that the scan stays quiet about it and loud about the rest.

## Stop the commit

A scan after the push is late, because the secret is already on the server. A pre-commit hook runs on the developer's machine before the commit exists. Create the hook file `.git/hooks/pre-commit`:

```sh
#!/bin/sh
gitleaks git --pre-commit --staged --redact
```

Make it executable:

```sh
chmod +x .git/hooks/pre-commit
```

The hook scans only the staged changes and refuses the commit when it finds a secret. A hook lives in one clone and can be skipped with `git commit --no-verify`, so also run the same scan in the pipeline that checks every pull request, where it cannot be skipped.

Two habits support the scan. Add the names of local key files to `.gitignore` (`*.agekey`, `age-keys/`), so a `git add .` cannot pick up an age identity. And keep the unencrypted source of a Secret outside the repository, so only the encrypted file exists inside it.

You can now search history, scan for credentials and block a commit that contains one. A leak that gets through anyway needs the opposite skill: removing the secret from history and, above all, replacing its value.

## Common pitfalls

> [!WARNING]
> - **Scanning only the working directory.** `gitleaks dir` does not read old commits. A secret deleted last week is still in history, so run `gitleaks git` as well.
> - **Trusting a local hook alone.** A developer can skip it with `--no-verify`, and a new clone has no hook. Run the scan in the pipeline too.
> - **Ignoring a finding without review.** An entry in `.gitleaksignore` hides a real secret forever. Review each one.
> - **Believing a clean scan proves safety.** A scanner finds known formats. A password in an unusual place may pass.
