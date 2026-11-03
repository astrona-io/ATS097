# Solution: Make The Receiver Check Signatures

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader runs 3 checks, one for each point under "Done when".

## Step 1: Read the Receiver

```sh
kubectl -n flux-system get receiver fleet-receiver -o jsonpath='{.spec.type}'; echo
flux get receivers
```

The type is `generic`.

## Step 2: Change the type

```sh
kubectl -n flux-system patch receiver fleet-receiver --type merge -p '{"spec":{"type":"generic-hmac"}}'
kubectl -n flux-system wait receiver/fleet-receiver --for=condition=Ready --timeout=120s
flux get receivers
```

The webhook path may change, so read `.status.webhookPath` again.

## Step 3: Send signed and unsigned requests

From a pod in the cluster, compute the signature of the body and send it:

```sh
TOKEN="$(kubectl -n flux-system get secret receiver-token -o jsonpath='{.data.token}' | base64 -d)"
BODY='{"lab":"ats-097"}'
SIG="sha256=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$TOKEN" | awk '{print $NF}')"
PATH_="$(kubectl -n flux-system get receiver fleet-receiver -o jsonpath='{.status.webhookPath}')"
kubectl -n gitea exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' -X POST -H "X-Signature: $SIG" --data-binary "$BODY" "http://webhook-receiver.flux-system.svc.cluster.local$PATH_"
```

A 2xx status means accepted. Repeat without the header: the status is not 2xx.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep `generic` and hide the path | The path is the only protection; the grader requires the signature check |
| Shorten the interval | The grader requires 30 minutes or more |
