# Solution: Seal A Secret With The Controller

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader runs 3 checks, one for each point under "Done when".

## Step 1: Install the controller

Save the HelmRepository and the HelmRelease from the reading as `sealed-secrets.yaml` and apply them:

```sh
kubectl apply -f sealed-secrets.yaml
flux get helmreleases -n flux-system
kubectl -n flux-system rollout status deploy/sealed-secrets-controller
```

The release becomes `Ready` and the Deployment is available.

## Step 2: Install kubeseal

Download the `kubeseal` release that matches the controller from the Sealed Secrets release page and put it on your PATH. Check it:

```sh
kubeseal --version
```

## Step 3: Remove the plain Secret and seal

The controller refuses to take over a Secret it does not own, so delete the plain Secret first:

```sh
kubectl -n podinfo delete secret podinfo-db
kubectl -n podinfo create secret generic podinfo-db --from-literal=password=sealed-in-lab --dry-run=client -o yaml \
  | kubeseal --controller-name=sealed-secrets-controller --controller-namespace=flux-system --format yaml \
  | kubectl apply -f -
```

## Step 4: Check the result

```sh
kubectl -n podinfo get sealedsecret,secret podinfo-db
kubectl -n podinfo get secret podinfo-db -o jsonpath='{.data.password}' | base64 -d; echo
```

The Secret holds `sealed-in-lab`, and `kubectl -n podinfo get secret podinfo-db -o jsonpath='{.metadata.ownerReferences[0].kind}'` prints `SealedSecret`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Annotate the plain Secret as managed | Works for adoption, but the grader wants the value `sealed-in-lab`, so the Secret must be recreated from the sealed value anyway |
| Seal with `--scope cluster-wide` | The value then decrypts anywhere in the cluster; the grader requires the strict scope |
