# Section 010: Secrets In GitOps

GitOps keeps the whole desired state of a cluster in Git, and that includes the objects that hold passwords. A Kubernetes Secret looks protected because its values are Base64-encoded, but Base64 is an encoding anyone can reverse. A Secret committed to Git is a password published to everyone who can read the repository, and Git keeps it in its history after the file is deleted.

This section shows the problem on a real repository, compares the ways GitOps teams solve it, and teaches the first thing to do when a secret has already been committed: take it out of Git without breaking the application, and rotate its value.

## What you will learn

- What Base64 does and does not do, and how to read a Secret's value from Git and from the cluster.
- Why deleting a committed file does not remove the secret from Git history.
- The options for secrets in GitOps: SOPS, Sealed Secrets, External Secrets Operator and a secret store, and when each fits.
- What Flux does with a Secret that leaves Git while pruning is on.
- How to remove a committed Secret, keep the application running, and rotate the exposed value.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Keep Plain Secrets Out Of Git

The playground runs `podinfo`, deployed by Flux from the repository `gitops/fleet`. The repository holds the Secret `podinfo-db` with its password in plain text.

1. Why A Plain Secret Cannot Go To Git
2. The Options For Secrets In GitOps
3. Removing A Secret That Was Committed, followed by the lab **Remove A Plain Secret From Git**
4. Summary

## Section capstone: Clean Every Credential Out Of The Repository

The capstone is one graded scenario that combines the module. The repository holds three credentials in three different forms: a Secret with `stringData`, a Secret with Base64 `data`, and a password in a ConfigMap. Find all three, take them out of Git while `podinfo` keeps running, and rotate every value. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS097.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-097-capstone-010
```
