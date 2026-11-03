# Generated Secrets And Their Limits

Kustomize can build a Secret from literals or files with `secretGenerator`. It is handy for examples and for secrets that are not sensitive, but it is easy to misuse in a GitOps repository. This part explains what it does and where it fits.

## What it does

In a `kustomization.yaml`:

<!-- astrona:playground:renew -->

```yaml
secretGenerator:
  - name: app-config
    literals:
      - mode=demo
```

Kustomize creates a Secret whose name has a hash suffix, for example `app-config-` followed by a short hash, and rewrites every reference to it in the same build. When the content changes, the hash changes, the name changes, and pods that reference it roll.

## Why it is not safe for real secrets

The literal or the file is stored in the repository in plain form, because kustomize reads it when it builds. A password in `secretGenerator` is therefore a password in Git. Use it for non-sensitive settings, or for files that are themselves decrypted before the build, as with SOPS-encrypted input files.

## Hash suffix and Flux

Flux applies the generated name as it is. Because `prune: true` removes objects that the new build no longer contains, the old Secret with the old hash is deleted after the rollout. Set `generatorOptions: { disableNameSuffixHash: true }` only when something outside the build must find the Secret by a fixed name, and accept that pods then do not roll on a change.

## Choosing

Use `secretGenerator` for non-sensitive generated config. Use SOPS, Sealed Secrets or the operator for anything secret. Use `postBuild.substituteFrom` and `valuesFrom` to refer to a Secret that arrives by one of those routes.

You can now use `secretGenerator` where it is safe and avoid it where it is not. The summary closes the module and the section.

## Common pitfalls

> [!WARNING]
> - **Putting a password in `literals`.** It is committed in plain form.
> - **Disabling the hash suffix and expecting a rollout.** Pods do not restart when the name stays the same.
> - **Referencing the generated Secret by its base name outside the build.** The real name has the suffix.

## Your mission: Fill A Manifest From A Secret

You can now do what the graded lab asks. It gives you a cluster with a fault or a missing piece, and you fix it on your own.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-097-playground-010-04
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-010/module-04/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-04/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-097-lab-010-04
astrona start ats-097-playground-010-04
```
