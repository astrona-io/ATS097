# Welcome To The Course

This course trains you for the **Secret Management, SOPS & Webhook Receivers** part of the Astrona **FluxCD** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Secrets, ConfigMaps, `kubectl apply` and `kubectl get`. You can use Git from the terminal: clone, commit, push and pull. You know what a Flux `GitRepository` and a Flux `Kustomization` do: the first makes Flux fetch a Git repository, the second makes Flux apply one folder of it to the cluster. You do not need to know SOPS, age or webhooks yet. Each new idea is explained the first time it appears.

## What you can do at the end

With GitOps, Git holds everything the cluster runs. That works well until something must stay private, and it is slow when the cluster checks Git only every few minutes. This course does not ask you to remember words. It asks you to keep secrets out of Git in plain text, make Flux use them anyway, and make Flux react to a push at once. The course has three topics.

The first topic is **secrets in GitOps**. You will learn to:

- Explain why a Kubernetes Secret in Git is readable by everyone who can read the repository, even years later.
- Find a committed secret in Git and in Git history, take it out of Git, and rotate its value.
- Compare SOPS, Sealed Secrets and External Secrets Operator, and say when each fits.

The second topic is **SOPS with age**. You will learn to:

- Create an age key pair and write SOPS creation rules in `.sops.yaml`.
- Encrypt a Kubernetes Secret so only its values are encrypted, and commit it.
- Give kustomize-controller the key and turn on decryption in a Flux `Kustomization`.
- Rotate a leaked key, and explain how a key management service (KMS) removes the key file altogether.

The third topic is **webhook receivers**. You will learn to:

- Explain why polling Git on an interval is slow and what a `Receiver` changes.
- Create a `Receiver` and a push webhook in the Git server that calls it.
- Prove that a push reaches the cluster within seconds.

Everything is written for **Flux v2.9.6**, **SOPS 3.13.3** and **age 1.3.2**.

## The words this course uses

The pages use Flux's, SOPS's, age's and Kubernetes' own terms, because those are the words you meet in the tools, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **Kubernetes Secret** holds small sensitive values, such as a password. Its values are Base64-encoded, which is an encoding anyone can reverse, not encryption. **SOPS** is a tool that encrypts the values in a YAML file and leaves the keys readable. **age** is the encryption tool and key format SOPS uses in this course. An age key pair has two halves:

| Half | What it does |
| --- | --- |
| Recipient (public key, starts with `age1`) | Encrypts. Safe to share and to commit |
| Identity (private key, starts with `AGE-SECRET-KEY-1`) | Decrypts. Never goes to Git |

A **`Receiver`** is a Flux object that gives the cluster a webhook address. When the Git server calls it after a push, Flux fetches the repository at once instead of at the next interval.

## The example setup in your playground

Every playground and lab runs the same small setup. A Git server called Gitea runs inside the cluster, in the namespace `gitea`, and holds the repository `gitops/fleet`. Flux reads that repository and deploys the demo application `podinfo`, a small web server, into the namespace `podinfo`. `podinfo` reads a password from the Secret `podinfo-db`, so a missing Secret stops it from starting new pods.

You work with the repository from your own machine: you clone it, change or encrypt a file, commit and push, and then watch what Flux does. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections. It starts with the problem, moves to the tool most Flux users choose for it, and ends with making every change arrive at once.

| Section | What it covers |
| --- | --- |
| 010 | Secrets In GitOps |
| 020 | SOPS With age |
| 030 | Webhook Receivers |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
