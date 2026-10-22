---
estimated_duration: 20m
---

# Remove A Plain Secret From Git

- **ID:** LAB
- **Slug:** ats-097-lab-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded environment for the namespaces `flux-system`, `podinfo` and `gitea`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Flux v2.9 and SOPS
> documentation and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-097-lab-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-097-lab-010-01`), not
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
