# Solution: One Receiver For Many Sources

Work the task yourself first. Running `astrona submit -c sections/section-030/module-04/labs/lab-01` after a step tells you which checks pass.

The grader runs 3 checks, one for each point under "Done when".

## Step 1: List the labeled sources

```sh
kubectl -n flux-system get gitrepositories,helmrepositories -L reconcile-on-push
```

## Step 2: Create the Receiver

Save this as `push-receiver.yaml` and apply it:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: push-receiver
  namespace: flux-system
spec:
  type: generic-hmac
  secretRef:
    name: receiver-token
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: GitRepository
      name: "*"
      matchLabels:
        reconcile-on-push: "true"
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: HelmRepository
      name: "*"
      matchLabels:
        reconcile-on-push: "true"
```

## Step 3: Send a signed request and compare

Compute the signature as in the reading and post to the webhook path from the tester pod. Then compare the annotation `reconcile.fluxcd.io/requestedAt` of each source:

```sh
kubectl -n flux-system get gitrepositories,helmrepositories -o custom-columns='NAME:.metadata.name,REQUESTED:.metadata.annotations.reconcile\.fluxcd\.io/requestedAt'
```

`fleet-skip` keeps its old value.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-04/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| List every source by name | Works for today's sources, but the grader requires the wildcard with labels |
| Label `fleet-skip` | Then it is reconciled too; the grader requires it to stay out |
