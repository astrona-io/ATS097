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

# 1. The Receiver must reconcile the GitRepository fleet.
kubectl -n flux-system patch receiver gitea-receiver --type=json \
  -p '[{"op":"replace","path":"/spec/resources/0/name","value":"fleet"}]'

# 2. The Gitea webhook must sign with the Receiver's token.
TOKEN="$(secret_value flux-system receiver-token token)"
HOOK_PATH="$(kubectl -n flux-system get receiver gitea-receiver -o jsonpath='{.status.webhookPath}')"
HOOK_ID="$(gitea_call GET "$REPO_PATH/hooks" | kubectl -n gitea exec -i deploy/tester -- jq -r '.[0].id')"
gitea_call PATCH "$REPO_PATH/hooks/$HOOK_ID" \
  "{\"active\":true,\"config\":{\"url\":\"http://webhook-receiver.flux-system.svc.cluster.local$HOOK_PATH\",\"content_type\":\"json\",\"secret\":\"$TOKEN\"}}" >/dev/null

# 3. Rotate the password in Git, encrypted for the recipient in .sops.yaml.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
git_read_file .sops.yaml > "$WORK/.sops.yaml"
mkdir -p "$WORK/apps/podinfo"
cat > "$WORK/apps/podinfo/secret.yaml" <<'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-db
  namespace: podinfo
type: Opaque
stringData:
  password: delivered-by-webhook
YAML
(cd "$WORK" && sops --encrypt --in-place apps/podinfo/secret.yaml)
git_put_file apps/podinfo/secret.yaml "Rotate the podinfo-db password" < "$WORK/apps/podinfo/secret.yaml"

# 4. No reconcile command: the push reaches the cluster through the webhook.
for _ in $(seq 1 45); do
  [ "$(secret_value podinfo podinfo-db password)" = "delivered-by-webhook" ] && break
  sleep 2
done
kubectl -n podinfo rollout restart deployment/podinfo
kubectl -n podinfo rollout status deployment/podinfo --timeout=180s
