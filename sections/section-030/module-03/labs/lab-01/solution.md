# Solution: Limit Who Can Call The Receiver

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass.

The grader runs 3 checks, one for each point under "Done when".

## Step 1: Read the policies

```sh
kubectl -n flux-system get networkpolicy
kubectl -n flux-system get networkpolicy allow-webhooks -o yaml
```

The policy `allow-webhooks` has an ingress rule without a `from`, so every source is allowed.

## Step 2: Remove it and add the limit

```sh
kubectl -n flux-system delete networkpolicy allow-webhooks
```

Save this as `limit-webhook.yaml` and apply it:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: limit-webhook
  namespace: flux-system
spec:
  podSelector:
    matchLabels:
      app: notification-controller
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: gitea
      ports:
        - protocol: TCP
          port: 9292
```

## Step 3: Check that the Git server still gets through

```sh
kubectl -n gitea exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' http://webhook-receiver.flux-system.svc.cluster.local/hook/none
```

Any HTTP status means the request arrived.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete every policy in `flux-system` | Other controllers lose their rules; the grader requires only `allow-webhooks` to go |
| Allow port `80` | The policy applies to the pod, which listens on `9292`; the Service maps `80` to it |
