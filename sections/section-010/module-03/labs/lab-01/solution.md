# Solution: Read A Secret From A Store

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass.

The grader runs 3 checks, one for each point under "Done when".

## Step 1: Install the operator

Save the HelmRepository and HelmRelease from the reading as `external-secrets.yaml` and apply them. Wait until the release is `Ready`:

```sh
kubectl apply -f external-secrets.yaml
flux get helmreleases -n flux-system
kubectl -n external-secrets get deploy
```

## Step 2: Create the store and the ExternalSecret

Save the `SecretStore` and the `ExternalSecret` from the reading as `eso-demo.yaml`, using the key `/podinfo/api-token`, the value `eso-lab-value` and the Secret name `api-credentials` with the key `token`. Apply it. If the apply reports that the kind is not known, the operator's CRDs are not ready yet; wait and apply again.

## Step 3: Check the result

```sh
kubectl -n podinfo get externalsecret api-credentials
kubectl -n podinfo get secret api-credentials -o jsonpath='{.data.token}' | base64 -d; echo
```

The `ExternalSecret` is ready and the Secret holds `eso-lab-value`.

## Step 4: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create the Secret by hand | The grader checks that the `ExternalSecret` owns it |
| Set `refreshInterval: 0` | The store is read once and never again; the grader requires an interval of 5 minutes or less |
