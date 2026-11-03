# Receivers As Code

A Receiver you create with `kubectl apply` by hand is a Receiver nobody can find again after the cluster is rebuilt. Flux manages itself from Git, so a Receiver belongs in the repository like every other object. The token is the one part that must not be there in plain text. This part creates a Receiver with the `flux` command, exports it as YAML, and stores its token encrypted with SOPS.

## Create the object with the flux command

The command `flux create receiver` builds the same object as the YAML you wrote before. It takes the type, the events, the token Secret and the resources:

<!-- astrona:playground:renew -->

```sh
flux create receiver fleet-hmac \
  --type generic-hmac \
  --secret-ref receiver-token \
  --resource GitRepository/fleet \
  --export > receiver-fleet-hmac.yaml
```

With `--export`, the command prints the YAML and creates nothing. The file now holds a Receiver you can review and commit. Without `--export`, it creates the object in the cluster at once, which is useful in an exercise and wrong for a repository.

## Keep the token Secret encrypted

The token must be in the cluster before the Receiver can become ready, and it must not be in Git as plain text. Create the Secret as a file, encrypt it with SOPS for the cluster's age recipient, and commit the encrypted file. Save this as `receiver-token.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: receiver-token
  namespace: flux-system
stringData:
  token: <TOKEN>
```

Put a random value in place of `<TOKEN>`, then encrypt the values with your recipient:

```sh
sops --encrypt --encrypted-regex '^(data|stringData)$' --age <RECIPIENT> --in-place receiver-token.yaml
```

The file keeps `kind` and `metadata` readable and holds the token as ciphertext. Commit it next to the Receiver, in a path that a Flux `Kustomization` with decryption turned on applies. That Flux `Kustomization` needs `spec.decryption.provider: sops` and a Secret that holds the age identity, so that kustomize-controller can decrypt the file before it applies it.

## What the repository then holds

After the commit, the repository holds the Receiver and the encrypted token. A new cluster gets both from Flux. The webhook in the Git server still needs the secret path and the token, which only a person or a script that can decrypt the file knows. Keep that step in a runbook, because the path changes whenever the token changes.

You can now create a Receiver as code, keep its token out of plain text, and rebuild the setup from Git. The module's summary follows.

## Common pitfalls

> [!WARNING]
> - **Committing the token Secret in plain text.** The Receiver's protection is gone as soon as the token is in history.
> - **Committing the Receiver without the Secret.** The Receiver stays not ready until the Secret exists.
> - **Running `flux create receiver` without `--export` and expecting a file.** The object goes straight to the cluster.

## Your mission: Make The Receiver Check Signatures

You can now do what the graded lab asks. It gives you a cluster with a fault or a missing piece, and you fix it on your own.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-097-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-097-lab-030-02
astrona start ats-097-playground-030-02
```
