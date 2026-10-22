# ATS097 — Secret Management, SOPS & Webhook Receivers (FluxCD)

Course material for the **Secret Management, SOPS & Webhook Receivers** domain
of the Astrona FluxCD training path ([ATP019](https://github.com/astrona-io/ATP019)),
which is **15% of the path**. Written for **Flux v2.9.6**, **SOPS 3.13.3** and
**age 1.3.2**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Flux v2.9 and SOPS documentation. None has been started on a
> cluster, and no lab has passed `astrona test` yet. See `CLAUDE.md` for the
> open risks, in the order to check them.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Secrets In GitOps | 1 | 1 + capstone | The problem and the options |
| [020](sections/section-020) | SOPS With age | 2 | 2 + capstone | Encryption and decryption |
| [030](sections/section-030) | Webhook Receivers | 1 | 1 + capstone | Reconciling on push |

The order follows the problem. Section 010 shows why a Secret cannot go to Git
in plain text and what a committed one costs. Section 020 encrypts Secrets with
SOPS and age and lets Flux decrypt them. Section 030 makes every push, including
a rotated Secret, reach the cluster within seconds.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Keep Plain Secrets Out Of Git](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Encrypt Secrets With SOPS And age](sections/section-020/module-01/course.md) | 2 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 020-02 | [Let Flux Decrypt Secrets In The Cluster](sections/section-020/module-02/course.md) | 2 | [lab-01](sections/section-020/module-02/labs/lab-01) |
| 030-01 | [Reconcile On Push With A Receiver](sections/section-030/module-01/course.md) | 2 | [lab-01](sections/section-030/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Clean Every Credential Out Of The Repository | a plain Secret, a Base64 Secret, a password in a ConfigMap |
| [020](sections/section-020/capstone/labs/lab-01) | Rotate A Leaked age Key | a leaked identity in the cluster, its recipient in `.sops.yaml` and in the encrypted file, the exposed value |
| [030](sections/section-030/capstone/labs/lab-01) | Deliver A Rotated Secret Without Waiting | a Receiver for the wrong `GitRepository`, a webhook signed with a different token, a value to rotate |

---

## The lab environment

Every playground and lab is a **kind** cluster with an in-cluster Git server
(Gitea, `gitea/gitea:28.2.0-rootless`) holding the private repository
`gitops/fleet`, the Flux controllers, and `flux`, `sops`, `age` and
`age-keygen` installed on the machine. The Flux objects (`GitRepository`
`fleet`, Flux `Kustomization` `podinfo`) are applied with `kubectl`.

The repository address is `http://gitea.localtest.me:3000/gitops/fleet.git`
everywhere: on the reader's machine through
`kubectl -n gitea port-forward svc/gitea-http 3000:3000`, and inside the
cluster through a CoreDNS rewrite added by the bootstrap. Credentials are the
lab-only `gitops` / `gitops-password`.

Every age key pair is generated at bootstrap time. No age identity is
committed to this repository or to `gitops/fleet`.

The environments' manifests and scripts were generated from one source and
share large blocks (the install step, the Gitea API helpers). When you change a
shared block, change it in every environment.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final cluster and Git state** with independent checks,
and several of them deliberately reject the plausible-but-wrong fix
(committing a value in plain text, committing an age identity, keeping a
leaked recipient, polling Git more often instead of fixing the webhook).
