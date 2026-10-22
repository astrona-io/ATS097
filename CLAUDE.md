# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS097 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Secret Management, SOPS & Webhook Receivers**
  domain of the **FluxCD** training path (`ATP019`). It is 15% of the path.
  There is no official Flux certification exam; the path's domains and weights
  are Astrona's own, set in `ATP019/path.yaml`.
- **What the domain really tests:** keeping credentials out of Git in plain
  text while Git stays the source of truth, and making Flux react to a push at
  once. The student must *do* things (find a committed secret and rotate it,
  create an age key, write `.sops.yaml`, encrypt a Secret with `sops`, give
  kustomize-controller the key, rotate a leaked key, connect a Git webhook to
  a `Receiver`). Every fix is proved with the value the Secret really holds in
  the cluster, the encrypted file in Git, and a revision that changes within
  seconds of a push.
- **The three topics:** secrets in GitOps and the options for them, SOPS with
  age (encrypting on the reader's machine and decrypting in the cluster), and
  webhook receivers.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Secrets In GitOps | The problem and the options |
  | 020 | SOPS With age | Encryption and decryption |
  | 030 | Webhook Receivers | Reconciling on push |

- **The versions:** **Flux v2.9.6**, **SOPS 3.13.3** and **age 1.3.2** on a
  single-node `kind` cluster (Kubernetes 1.34.1 or later). Do not teach flags
  or output from other versions without saying so.
- **The main sources:** the Flux documentation, <https://fluxcd.io/flux/>
  (in particular the SOPS guide and the Receiver API), and the SOPS
  documentation, <https://getsops.io/docs/>. Check every page against them.

### Status: built, not yet run

The first version of this repository was written from the Flux v2.9 and SOPS
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The open risks, in the order to check them:

1. **Git credentials over plain HTTP.** The Flux documentation describes basic
   authentication for HTTPS only, and the repository `gitops/fleet` is
   private, so every `GitRepository` sends the `gitops` credentials to
   `http://gitea.localtest.me:3000`. If source-controller or
   `flux create secret git` refuses that, every environment fails at the first
   fetch. The fallback is Gitea on HTTPS with a self-signed certificate.
2. **Gitea webhooks into the cluster.** Gitea blocks webhook targets on private
   addresses unless `[webhook] ALLOWED_HOST_LIST` allows them; the manifests set
   `GITEA__webhook__ALLOWED_HOST_LIST=private`. The `webhook-receiver` Service
   is assumed to listen on port `80`. The Flux docs say to use the `github`
   Receiver type for Gitea; that relies on Gitea sending the GitHub headers
   (`X-GitHub-Event`, `X-Hub-Signature-256`) for a webhook of type `gitea`.
3. **What kustomize-controller does with a SOPS file and no decryption
   settings.** The pages only say that the Secret is not created with the real
   value and tell the reader to read `flux events`. Check the real message and
   add it in words.

### Terms, not metaphors

Explanations use Flux's, SOPS's, age's and Kubernetes' own words. Define each
one in plain technical language on first use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| Kubernetes Secret | An object that holds small sensitive values; `data` values are only Base64-encoded, which is an encoding, not encryption |
| SOPS | A command-line tool that encrypts the values in a YAML or JSON file and leaves the keys and the structure readable |
| age | A small file encryption tool and key format; SOPS can use an age key pair to encrypt and decrypt |
| age recipient / age identity | The public key, starting with `age1`, that encrypts / the private key, starting with `AGE-SECRET-KEY-1`, that decrypts |
| Data key | The random key SOPS creates for each file to encrypt its values; SOPS encrypts the data key once for every recipient |
| `.sops.yaml` | The SOPS configuration file at the repository root; its `creation_rules` say which files use which recipients |
| `encrypted_regex` | A regular expression that selects which keys SOPS encrypts, here `^(data|stringData)$`, so `kind` and `metadata` stay readable |
| `sops:` metadata | The block SOPS adds to an encrypted file: the encrypted data keys, the recipients, a message authentication code (MAC) and the time |
| Decryption provider | The setting `spec.decryption.provider: sops` on a Flux `Kustomization`; kustomize-controller then decrypts SOPS files before it applies them |
| Key management service (KMS) | A cloud service (AWS KMS, Google Cloud KMS, Azure Key Vault) or HashiCorp Vault that holds the key so that no private key file exists |
| Sealed Secrets | A controller that decrypts `SealedSecret` objects encrypted with its own public key |
| External Secrets Operator | A controller that copies values from an external secret store into Kubernetes Secrets, so Git holds only a reference |
| `Receiver` | The Flux object (notification-controller) that exposes a webhook path and reconciles the listed objects when a valid request arrives |
| Webhook path | `.status.webhookPath`, `/hook/` followed by a SHA-256 of the token, the name and the namespace |
| HMAC signature | A hash of the request body made with a shared secret; the `github` and `generic-hmac` Receiver types check it, so only someone with the token can trigger a reconcile |

Never call encryption "locking" or a key "a padlock". Never say Base64
"hides" a value: it encodes it.

### The example workloads

| Name | Image | What it is |
| --- | --- | --- |
| `gitea` (Deployment and Service `gitea-http`, namespace `gitea`) | `gitea/gitea:28.2.0-rootless` | The in-cluster Git server. HTTP on port `3000`. SQLite storage on an `emptyDir`. `GITEA__webhook__ALLOWED_HOST_LIST=private` lets it call the Receiver |
| Gitea user `gitops` | | Password `gitops-password`, administrator. Lab-only credentials; say so when a page uses them |
| Repository `gitops/fleet` | | The cluster's private Git repository. Every module seeds it with its own starting files |
| `podinfo` (Deployment and Service, namespace `podinfo`) | `ghcr.io/stefanprodan/podinfo:6.15.0` | The application. Its Deployment reads the Secret `podinfo-db` (key `password`) into an environment variable, so a missing Secret stops new pods |
| `tester` (namespace `gitea`) | `nicolaka/netshoot:v0.13` | Client pod with `curl` and `jq`. Scripts and graders call the Gitea API from here |
| Secret `podinfo-db` (namespace `podinfo`) | | The example credential, key `password` |
| Secret `sops-age` (namespace `flux-system`) | | The age identity kustomize-controller decrypts with, key `age.agekey` (the key name must end in `.agekey`) |
| Secret `team-age-key` (namespace `gitea`) | | Where a lab hands the reader an existing age identity, key `age.agekey` |

Labs generate every age key pair at bootstrap time on the reader's machine.
**No age identity is ever committed to this repository or to `gitops/fleet`.**
Graders check that no file in `gitops/fleet` contains `AGE-SECRET-KEY-`.

The `gitops/fleet` layout:

```text
fleet/
├── .sops.yaml             # SOPS creation rules (section 020 and later)
├── apps/podinfo/          # namespace.yaml, deployment.yaml, service.yaml, kustomization.yaml, secret.yaml
├── secrets/podinfo/       # encrypted Secrets no Flux Kustomization applies (section 020, module 01)
└── clusters/kind/         # README only
```

### Environment facts the text must respect

- **One Git address everywhere: `http://gitea.localtest.me:3000`.** On the
  reader's machine through `kubectl -n gitea port-forward svc/gitea-http
  3000:3000`; inside the cluster through a CoreDNS `rewrite stop` block that
  rewrites the question to `gitea-http.gitea.svc.cluster.local` and the answer
  back to `gitea.localtest.me` (Go programs ignore an answer whose name differs
  from the question). Copy the block from
  `sections/section-010/module-01/playground/bootstrap/prepare.sh`; never the
  one-line `rewrite name` form. If the reader's router blocks DNS answers
  that point at `127.0.0.1`, they add `127.0.0.1 gitea.localtest.me` to
  `/etc/hosts`; every page that clones says so in one sentence.
- **Tools on the reader's machine.** Every playground and lab installs
  `flux` 2.9.6, `sops` 3.13.3 and `age`/`age-keygen` 1.3.2 from their GitHub
  releases into `/usr/local/bin` or `~/.local/bin`. The reader needs `git`.
- **The Flux objects.** Every environment creates the Secret `fleet-auth`
  (`flux create secret git`), the `GitRepository` `fleet` (branch `main`) and
  the Flux `Kustomization` `podinfo` (path `./apps/podinfo`, `prune: true`)
  with `kubectl apply`, not with bootstrap. In section 030 the `GitRepository`
  interval is `1h`, so only a webhook explains a fast update.
- **SOPS facts (from the documentation, not yet seen on a run):**
  - `age-keygen -o age.agekey` writes an identity and prints its recipient;
    `age-keygen -y age.agekey` prints the recipient of an existing identity.
  - `sops --encrypt --in-place <file>` uses the first `creation_rules` entry
    in `.sops.yaml` whose `path_regex` matches; `--age <recipient>` and
    `--encrypted-regex` set the same things on the command line.
  - `sops --decrypt <file>` needs the identity in `SOPS_AGE_KEY_FILE` or
    `SOPS_AGE_KEY`.
  - `sops updatekeys -y <file>` changes the recipients to match `.sops.yaml`;
    `sops rotate --in-place <file>` creates a new data key.
  - A recipient removed with `updatekeys` can still decrypt every older
    version of the file in Git history. A leaked key always means a new value.
- **Flux facts:** `spec.decryption.provider: sops` with `secretRef.name:
  sops-age` on a Flux `Kustomization`; the key in that Secret must end in
  `.agekey`. Receiver API `notification.toolkit.fluxcd.io/v1`; types
  `generic`, `generic-hmac`, `generic-oidc`, `github`, `gitlab`,
  `bitbucket`, `harbor`, `dockerhub`, `quay`, `nexus`, `acr`, `gcr`,
  `cdevents`; the Secret key is `token`; Gitea uses the `github` type.
- **Many environments start broken on purpose.** The fault is the material.
  Never fix it in the bootstrap.
- **The proof.** A Secret fix is proven with the value in the cluster
  (`kubectl get secret -o jsonpath` and `base64 -d`), the file in Git, and a
  ready Flux `Kustomization`. A Receiver fix is proven by a commit whose
  revision source-controller holds within seconds, while the interval is an
  hour.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/01-install-git-and-flux.sh` | Flux, SOPS and age on the machine, Gitea, the CoreDNS rewrite, the repository seed and `flux install` (the same in every environment) |
| `bootstrap/02-seed-state.sh` | The lab's starting state: keys, encrypted files, Flux objects, the fault |
| `manifests/` | `lab-start.yaml` (Gitea and tester), `repo/` (files seeded into `gitops/fleet`), `sync.yaml` (Flux objects) |
| `solution/apply.sh` | Reference end state, applied only by `astrona test`; it changes Git through the Gitea API because `astrona test` has no port-forward |
| `testing/wait-for-flux.sh` | Waits until Gitea and the Flux controllers answer |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS097`, domain
`Secret Management, SOPS & Webhook Receivers`, weight `15`) and one entry
per section under `modules:`. Each `type: lab` entry carries `title`, `path`,
`difficulty`, `estimated_duration`, `topic`, `task_kind`, `tags`,
`learning_goals`, `resources`, in that order, as in ATS094.

- `topic`: exactly one of `secrets-in-git`, `sops-encryption`,
  `sops-decryption`, `key-rotation`, `receivers`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below.
- `resources`: 1 to 4 pages on `fluxcd.io` or `getsops.io`.

**Tag list** (lower case, hyphens, never synonyms):

- Secrets: `kubernetes-secret`, `base64`, `git-history`, `secret-rotation`,
  `sealed-secrets`, `external-secrets`, `prune`
- SOPS and age: `sops`, `age`, `sops-config`, `encrypted-regex`,
  `age-recipient`, `updatekeys`, `kms`
- Flux: `kustomization`, `decryption`, `sops-age-secret`, `gitrepository`,
  `flux-reconcile`, `flux-events`
- Receivers: `receiver`, `webhook`, `hmac`, `gitea-webhook`,
  `webhook-path`, `interval`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-010/module-01/playground
astrona destroy ats-097-playground-010-01

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-097-lab-010-01

# Authors
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-097-playground-<section>-<module>`, a module lab
is `ats-097-lab-<section>-<module>` and a capstone is
`ats-097-capstone-<section>`.

Graders check **behaviour**: the decrypted value in the cluster, the
encrypted file in Git, a revision that changed because of a webhook. Graders
also reject the plausible but wrong fix: committing the Secret in plain text
"just for now", committing the age identity, lowering the `GitRepository`
interval instead of fixing the webhook, keeping the leaked key as a second
recipient, or keeping the leaked value after a key rotation.

Graders and solutions use the `flux`, `sops` and `age-keygen` binaries on the
machine, so `01-install-git-and-flux.sh` installs them in every lab.

### Where to find trusted sources

- **Flux:** [Manage Kubernetes secrets with SOPS](https://fluxcd.io/flux/guides/mozilla-sops/),
  [Kustomization decryption](https://fluxcd.io/flux/components/kustomize/kustomizations/#decryption),
  [Receivers](https://fluxcd.io/flux/components/notification/receivers/),
  [webhook receivers guide](https://fluxcd.io/flux/guides/webhook-receivers/),
  [Sealed Secrets guide](https://fluxcd.io/flux/guides/sealed-secrets/)
- **SOPS:** [documentation](https://getsops.io/docs/)
- **age:** <https://github.com/FiloSottile/age>
- **Gitea:** [webhooks](https://docs.gitea.com/usage/webhooks),
  [configuration cheat sheet `[webhook]`](https://docs.gitea.com/administration/config-cheat-sheet#webhook-webhook)

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
