# Solution: Add A Backup Recipient To An Encrypted File

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass.

The grader runs 4 checks, one for each point under "Done when".

## Step 1: Clone and read the recipients

```sh
kubectl -n gitea get secret team-age-key -o jsonpath='{.data.age\.agekey}' | base64 -d > team.agekey
kubectl -n gitea get secret backup-age-key -o jsonpath='{.data.age\.agekey}' | base64 -d > backup.agekey
age-keygen -y team.agekey
age-keygen -y backup.agekey
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
```

## Step 2: Edit the creation rule

In `fleet/.sops.yaml`, change the `age:` line to hold both recipients, separated by a comma.

## Step 3: Update the file

```sh
cd fleet
SOPS_AGE_KEY_FILE=../team.agekey sops updatekeys -y apps/podinfo/secret.yaml
```

The command re-wraps the data key for both recipients and does not change the values.

## Step 4: Commit, push and check

```sh
git add .sops.yaml apps/podinfo/secret.yaml && git commit -m "Add the backup recipient" && git push
SOPS_AGE_KEY_FILE=../backup.agekey sops --decrypt apps/podinfo/secret.yaml
flux reconcile kustomization podinfo --with-source
```

The backup identity decrypts the file and the Kustomization stays `Ready`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Re-encrypt the file from the plain value | Works, but you must know the plain value; `updatekeys` needs only the current identity |
| Replace the team recipient with the backup | Flux decrypts with `sops-age`, which holds only the team identity; the file must keep the team recipient |
