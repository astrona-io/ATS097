---
estimated_duration: 30m
---

# Clean Every Credential Out Of The Repository

- **ID:** CAPSTONE
- **Slug:** ats-097-capstone-010
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Graded environment for the namespaces `flux-system`, `podinfo` and `gitea`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Flux v2.9 and SOPS
> documentation and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-097-capstone-010
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-097-capstone-010`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | flux, sops, age, Gitea, CoreDNS rewrite and `flux install`, then the starting state |
| `manifests/` | `lab-start.yaml` (Gitea, tester), `repo/` (files seeded into `gitops/fleet`), `sync.yaml` (Flux objects) |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for Gitea and the Flux controllers |
| `validation/` | Grading scripts, one per check |
