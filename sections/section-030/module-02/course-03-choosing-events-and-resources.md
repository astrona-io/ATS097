# Choosing Events And Resources

An accepted request does two more things that you control: it checks the event type, and it reconciles a list of objects. Getting these two fields right keeps the Receiver doing exactly one job. Getting them wrong makes a Receiver that either never acts or reconciles far too much. This part explains both fields and the choices behind them.

## Filter by event

For the types where the sender names the event in a header, `spec.events` limits which events act. A `github` Receiver with `events: ["push"]` ignores a `ping` or a `release` event, and answers that the event is not allowed. An empty list accepts every event. The `ping` event is what a Git server sends when you create or test a webhook, so while you set one up, list both `ping` and `push`, and remove `ping` afterwards if you like.

The names differ between senders. GitHub and Gitea write `push`. GitLab writes `Push Hook`. Bitbucket writes `repo:push`. Check the sender's header value, because a filter that does not match makes the Receiver look broken when it is working as written.

For `generic` and `generic-hmac`, no header names an event, so the filter does not apply. The type accepts any request that passes its check.

## Choose the resources

`spec.resources` lists what to reconcile. Each entry has an `apiVersion`, a `kind` and a `name`. A Receiver can list several entries, and they may be of different kinds. Save this as `receiver-multi.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: multi-receiver
  namespace: flux-system
spec:
  type: generic-hmac
  secretRef:
    name: receiver-token
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: GitRepository
      name: fleet
    - apiVersion: kustomize.toolkit.fluxcd.io/v1
      kind: Kustomization
      name: podinfo
```

Apply it and read the status:

```sh
kubectl apply -f receiver-multi.yaml
flux get receivers
```

The second entry makes the Receiver ask the Flux `Kustomization` `podinfo` to reconcile too. That is rarely what you want after a push, because kustomize-controller already reconciles when the source changes. Reconciling the Kustomization at the same moment as the source can apply the old revision first. List the source, and let the Kustomization follow.

## Wildcards and namespaces

An entry can use `name: "*"` together with `matchLabels` to select every object of that kind with the labels, in the namespace of the Receiver. Use it when one webhook must refresh many sources, for example every `OCIRepository` for one application. By default, the objects must be in the same namespace as the Receiver, and the Receiver needs no permission outside it. An entry may name another namespace with the `namespace` field, so a Receiver in `flux-system` can serve sources elsewhere.

A wildcard entry is convenient and wide. A request that passes the check reconciles all the objects it selects, so keep the labels narrow.

You can now choose which events a Receiver accepts and which objects it reconciles, and you know why listing a Kustomization next to its source is a mistake. The last part keeps these objects in Git.

## Common pitfalls

> [!WARNING]
> - **Writing the GitHub event name for a GitLab sender.** GitLab sends `Push Hook`. A mismatch rejects every request.
> - **Listing both the source and its Kustomization.** The Kustomization can apply the previous revision.
> - **Using `name: "*"` without labels.** It reconciles every object of that kind in the namespace.
> - **Expecting `events` to filter a `generic-hmac` Receiver.** Those types have no event header.
