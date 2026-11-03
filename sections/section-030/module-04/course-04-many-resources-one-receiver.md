# Many Resources, One Receiver

A cluster with one application needs one Receiver. A platform with fifty tenants and a registry per team needs a way to organise them. The choices are one Receiver for many sources, or one Receiver for each source, and each has costs. This part shows how to select many resources, how to name and label Receivers, and what to watch when there are many.

## Select by label

An entry in `spec.resources` can use `name: "*"` together with `matchLabels`, so that it selects every object of that kind that carries the labels. Label the sources first:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system label ocirepository podinfo-config team=payments
```

Save this as `receiver-payments.yaml`:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: payments-receiver
  namespace: flux-system
spec:
  type: generic-hmac
  secretRef:
    name: receiver-token
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: OCIRepository
      name: "*"
      matchLabels:
        team: payments
```

Apply it:

```sh
kubectl apply -f receiver-payments.yaml
```

Every `OCIRepository` in the namespace with the label `team: payments` is refreshed by one request. A new source with that label joins without any change to the Receiver.

## One Receiver for each source or for each team

One Receiver per source gives the finest control: its own token, its own path, and a rotation that touches one sender. It costs more objects and more webhooks to configure. One Receiver per team or per registry is a middle path. One Receiver for the whole cluster is the simplest and the least safe, because every sender shares one token and every request refreshes everything.

A good rule is to share a Receiver only between resources that always change together, and to give each sender its own token.

## What to watch

Count the objects behind each Receiver. A request that refreshes a hundred sources makes a hundred fetches at once, which a registry may rate-limit. Spread the load by narrowing labels or by using the filter. Read the status of all Receivers together and look for any that are not ready:

```sh
flux get receivers --all-namespaces
```

Add a label such as `team` to the Receivers themselves, so that you can list, export and delete the Receivers of one team with one selector.

You can now organise Receivers for many sources: select resources by label, decide how many Receivers to run, and keep the load and the tokens under control. The summary that follows closes the module.

## Common pitfalls

> [!WARNING]
> - **A wildcard without labels.** It selects every object of that kind in the namespace.
> - **Sharing one token between all senders.** Rotating it breaks every sender.
> - **Ignoring registry rate limits.** A request that refreshes many sources can trigger them.

## Your mission: One Receiver For Many Sources

You can now do what the graded lab asks. It gives you a cluster with a fault or a missing piece, and you fix it on your own.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-097-playground-030-04
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-030/module-04/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-04/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-097-lab-030-04
astrona start ats-097-playground-030-04
```
