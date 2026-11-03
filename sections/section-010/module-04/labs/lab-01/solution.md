# Solution: Fill A Manifest From A Secret

Work the task yourself first. Running `astrona submit -c sections/section-010/module-04/labs/lab-01` after a step tells you which checks pass.

The grader runs 3 checks, one for each point under "Done when".

## Step 1: Read the problem

```sh
kubectl -n podinfo get configmap banner -o jsonpath='{.data.text}'; echo
```

The ConfigMap holds the literal `${banner_text}`.

## Step 2: Create the Secret

```sh
kubectl -n flux-system create secret generic cluster-secrets --from-literal=banner_text=hello-from-secret
```

## Step 3: Turn on substitution

```sh
kubectl -n flux-system patch kustomization podinfo --type merge \
  -p '{"spec":{"postBuild":{"substituteFrom":[{"kind":"Secret","name":"cluster-secrets"}]}}}'
flux reconcile kustomization podinfo --with-source
```

## Step 4: Check the result

```sh
kubectl -n podinfo get configmap banner -o jsonpath='{.data.text}'; echo
```

The command prints `hello-from-secret`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-04/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Write the value into `banner.yaml` | Works, but the value is now in Git; the grader requires the placeholder |
| Put the Secret in `podinfo` | `substituteFrom` reads from the namespace of the Kustomization, which is `flux-system` |
