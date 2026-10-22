#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
#
# `astrona test` has no port-forward to Gitea, so the Git changes go through
# the Gitea API from the tester pod instead of `git push`. The learner makes
# the same changes with a clone, a commit and a push.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

GIT_AUTH="gitops:gitops-password"
GITEA_API="http://gitea-http.gitea:3000/api/v1"
REPO_PATH="/repos/gitops/fleet"

gitea_call() {
  # gitea_call METHOD PATH [JSON]: calls the Gitea API from the tester pod and
  # prints the response body. Fails on an HTTP error.
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | kubectl -n gitea exec -i deploy/tester -- \
      curl -fsS -u "$GIT_AUTH" -X "$method" -H 'Content-Type: application/json' \
      --data-binary @- "$GITEA_API$path"
  else
    kubectl -n gitea exec deploy/tester -- \
      curl -fsS -u "$GIT_AUTH" -X "$method" "$GITEA_API$path"
  fi
}

git_read_file() {
  # git_read_file REPO_FILE: prints the file from branch main, fails if missing.
  gitea_call GET "$REPO_PATH/raw/$1?ref=main"
}

git_file_sha() {
  # git_file_sha REPO_FILE: prints the blob SHA, or nothing if the file is missing.
  gitea_call GET "$REPO_PATH/contents/$1?ref=main" 2>/dev/null \
    | kubectl -n gitea exec -i deploy/tester -- jq -r '.sha // empty' 2>/dev/null || true
}

git_put_file() {
  # git_put_file REPO_FILE MESSAGE < CONTENT: creates or updates one file on main.
  local path="$1" message="$2" content sha
  content="$(base64 | tr -d '\n')"
  sha="$(git_file_sha "$path")"
  if [ -n "$sha" ]; then
    gitea_call PUT "$REPO_PATH/contents/$path" \
      "{\"content\":\"$content\",\"sha\":\"$sha\",\"message\":\"$message\",\"branch\":\"main\"}" >/dev/null
  else
    gitea_call POST "$REPO_PATH/contents/$path" \
      "{\"content\":\"$content\",\"message\":\"$message\",\"branch\":\"main\"}" >/dev/null
  fi
}

git_delete_file() {
  # git_delete_file REPO_FILE MESSAGE: deletes one file on main, if it exists.
  local sha
  sha="$(git_file_sha "$1")"
  [ -n "$sha" ] || return 0
  gitea_call DELETE "$REPO_PATH/contents/$1" \
    "{\"sha\":\"$sha\",\"message\":\"$2\",\"branch\":\"main\"}" >/dev/null
}

git_head_sha() {
  # git_head_sha: prints the commit SHA at the tip of main.
  gitea_call GET "$REPO_PATH/branches/main" \
    | kubectl -n gitea exec -i deploy/tester -- jq -r '.commit.id'
}

git_tree_paths() {
  # git_tree_paths: prints the path of every file on main, one per line.
  gitea_call GET "$REPO_PATH/git/trees/$(git_head_sha)?recursive=true&per_page=1000" \
    | kubectl -n gitea exec -i deploy/tester -- jq -r '.tree[] | select(.type == "blob") | .path'
}

secret_value() {
  # secret_value NAMESPACE NAME KEY: prints one decoded value of a Secret.
  kubectl -n "$1" get secret "$2" -o jsonpath="{.data.${3//./\\.}}" 2>/dev/null | base64 -d 2>/dev/null
}

recipients_in() {
  # recipients_in < FILE: prints every age recipient listed in a file.
  grep -oE 'age1[0-9a-z]{58}' | sort -u
}

recipient_of_identity() {
  # recipient_of_identity < IDENTITY_FILE: prints the age recipient of each identity.
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  grep -E '^AGE-SECRET-KEY-1' "$tmp" | while read -r identity; do
    printf '%s\n' "$identity" | age-keygen -y
  done
  rm -f "$tmp"
}

# 1. Create the new Secrets outside Git first, under names Git does not use
#    (podinfo-smtp) or after Flux has pruned the old ones (the other two).
kubectl -n podinfo create secret generic podinfo-smtp --from-literal=password=rotated-smtp-2026 \
  --dry-run=client -o yaml | kubectl apply -f -

# 2. Change Git: the Deployment reads SMTP_PASSWORD from podinfo-smtp, the
#    ConfigMap keeps only smtp-host, and both Secrets leave Git.
git_put_file apps/podinfo/deployment.yaml "Read the SMTP password from a Secret" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: podinfo
  labels:
    app: podinfo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
        - name: podinfo
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          env:
            - name: PODINFO_UI_MESSAGE
              value: "deployed by Flux"
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: podinfo-db
                  key: password
            - name: API_TOKEN
              valueFrom:
                secretKeyRef:
                  name: podinfo-api
                  key: token
            - name: SMTP_HOST
              valueFrom:
                configMapKeyRef:
                  name: podinfo-settings
                  key: smtp-host
            - name: SMTP_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: podinfo-smtp
                  key: password
          ports:
            - name: http
              containerPort: 9898
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
YAML
git_put_file apps/podinfo/settings.yaml "Keep only non-secret settings in the ConfigMap" <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-settings
  namespace: podinfo
data:
  smtp-host: smtp.example.com
YAML
git_put_file apps/podinfo/kustomization.yaml "Stop applying Secrets from Git" <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - settings.yaml
  - deployment.yaml
  - service.yaml
YAML
git_delete_file apps/podinfo/secret.yaml "Remove the plain podinfo-db Secret"
git_delete_file apps/podinfo/api-secret.yaml "Remove the plain podinfo-api Secret"

# 3. Apply, wait for Flux to prune the two Secrets, then create them with new values.
flux reconcile kustomization podinfo --with-source --timeout=5m || true
for _ in $(seq 1 30); do
  kubectl -n podinfo get secret podinfo-db >/dev/null 2>&1 || \
    kubectl -n podinfo get secret podinfo-api >/dev/null 2>&1 || break
  sleep 2
done
kubectl -n podinfo create secret generic podinfo-db --from-literal=password=rotated-db-2026
kubectl -n podinfo create secret generic podinfo-api --from-literal=token=rotated-api-2026
kubectl -n podinfo rollout restart deployment/podinfo
flux reconcile kustomization podinfo --timeout=5m
kubectl -n podinfo rollout status deployment/podinfo --timeout=180s
