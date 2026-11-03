# How Each Receiver Type Validates A Request

Every Receiver has the same fields, but its `type` changes what notification-controller does with an incoming request. Some types prove that the sender knows a secret, and some only rely on the address being hard to guess. Before you pick a type, you need to know what each one gives you, because the choice sets how much an attacker who finds the address can do.

## What every type has in common

For every type, the address of the Receiver is the secret path in `.status.webhookPath`. A request to any other path under `/hook/` is rejected as unknown. For every type, a request that passes the check makes notification-controller set the annotation `reconcile.fluxcd.io/requestedAt` on each object in `spec.resources`, and the controller of that object then reconciles it at once.

Create a token Secret and a first Receiver to look at the status:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system create secret generic receiver-token --from-literal=token="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
```

Save this as `receiver-generic.yaml`:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: generic-receiver
  namespace: flux-system
spec:
  type: generic
  secretRef:
    name: receiver-token
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: GitRepository
      name: fleet
```

Apply it and read the path:

```sh
kubectl apply -f receiver-generic.yaml
kubectl -n flux-system get receiver generic-receiver -o jsonpath='{.status.webhookPath}{"\n"}'
```

## The validation of each type

The table lists how each type checks a request. The first four are the ones you meet most often.

| Type | What notification-controller checks |
| --- | --- |
| `generic` | Nothing beyond the path. Any `POST` to the path triggers a reconcile |
| `generic-hmac` | The header `X-Signature` holds an HMAC of the request body, made with the token, written as `sha256=` and the hex value (`sha1=` and `sha512=` also work) |
| `github` | The header `X-Hub-Signature-256` (or `X-Hub-Signature`) holds an HMAC of the body made with the token. The header `X-GitHub-Event` is matched against `spec.events` |
| `gitlab` | The header `X-Gitlab-Token` equals the token. The header `X-Gitlab-Event` is matched against `spec.events` |
| `bitbucket` | The header `X-Hub-Signature` holds an HMAC of the body. The header `X-Event-Key` is matched against `spec.events` |
| `harbor` | The header `Authorization` equals the token |
| `nexus` | The header `X-Nexus-Webhook-Signature` holds an HMAC of the body |
| `dockerhub`, `quay`, `acr` | The secret path only, because these registries cannot sign a request |
| `generic-oidc` | A signed OpenID Connect token from the sender, instead of a shared secret |

Two things follow from the table. A type that checks a signature protects you even if the path appears in a log, because an attacker without the token cannot compute a valid signature. A type that checks only the path is as strong as the secrecy of the path, so put such a Receiver behind network limits.

## Why the signature covers the body

An HMAC is a hash computed from the body and a secret key. If anyone changes the body in transit, the hash no longer matches, so a valid signature also proves that the body is the one the sender made. A `generic` Receiver gives no such proof, but for Flux it matters little, because the body of a reconcile request does not decide what happens. The risk of an unsigned Receiver is not a changed body. It is a stranger who can trigger reconciles at will, which can be used to put load on the Git server or on the cluster.

You can now say how each type validates a request, and which types to avoid on an address that is open to the internet. The next part builds both a valid and an invalid request by hand.

## Common pitfalls

> [!WARNING]
> - **Choosing `generic` because it is simplest.** It works with every sender, and it gives no protection beyond the path.
> - **Using the `github` type for a sender that signs differently.** The request is rejected. Gitea works with `github` because it sends the same headers.
> - **Looking for the token in the URL.** The token is never in the URL. The path is a hash derived from it.
