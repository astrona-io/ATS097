# Solution: Give Each Tenant Its Own Key

Work the task yourself first. Running `astrona submit -c sections/section-020/module-04/labs/lab-01` after a step tells you which checks pass.

The grader runs 4 checks, one for each point under "Done when".

## Step 1: Find the cause

```sh
flux get kustomizations
kubectl -n flux-system describe kustomization tenant-b
```

The message says the decryption failed, because `sops-age` holds the key of tenant a only.

## Step 2: Create tenant b's Secret

```sh
kubectl -n gitea get secret tenant-b-key -o jsonpath='{.data.age\.agekey}' | base64 -d > b.agekey
kubectl -n flux-system create secret generic sops-age-b --from-file=age.agekey=b.agekey
rm b.agekey
```

## Step 3: Point tenant-b at it

```sh
kubectl -n flux-system patch kustomization tenant-b --type merge \
  -p '{"spec":{"decryption":{"provider":"sops","secretRef":{"name":"sops-age-b"}}}}'
flux reconcile kustomization tenant-b --with-source
```

## Step 4: Check the result

```sh
flux get kustomizations
kubectl -n tenant-b get secret app-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-04/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add tenant b's identity to `sops-age` | Both tenants then decrypt with both keys; the grader requires `sops-age` to hold only tenant a's key |
| Decrypt the file and commit it plain | The grader requires both files to stay encrypted in Git |
