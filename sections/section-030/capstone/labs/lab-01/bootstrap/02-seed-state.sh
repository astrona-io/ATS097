#!/usr/bin/env bash
# Creates the starting state for ats-097-capstone-030.
#
# Commits an encrypted podinfo-db Secret that Flux decrypts with sops-age, sets the GitRepository interval to one hour, and creates a Receiver for the wrong GitRepository plus a Gitea webhook with a different secret than the Receiver's token.
#
# The fixed state is NOT created here — producing it is the task.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

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

KEY_DIR="$(mktemp -d)"
age-keygen -o "$KEY_DIR/age.agekey" 2>/dev/null
TEAM_RECIPIENT="$(age-keygen -y "$KEY_DIR/age.agekey")"
kubectl -n gitea create secret generic team-age-key \
  --from-file=age.agekey="$KEY_DIR/age.agekey" --dry-run=client -o yaml | kubectl apply -f -

SECRET_VALUE="before-webhook"

cat > "$KEY_DIR/.sops.yaml" <<YAML
creation_rules:
  - path_regex: .*\.yaml\$
    encrypted_regex: ^(data|stringData)\$
    age: $TEAM_RECIPIENT
YAML
mkdir -p "$KEY_DIR/apps/podinfo"
cat > "$KEY_DIR/apps/podinfo/secret.yaml" <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-db
  namespace: podinfo
type: Opaque
stringData:
  password: $SECRET_VALUE
YAML
(cd "$KEY_DIR" && sops --config .sops.yaml --encrypt --in-place apps/podinfo/secret.yaml)
git_put_file .sops.yaml "Add SOPS creation rules" < "$KEY_DIR/.sops.yaml"
git_put_file apps/podinfo/secret.yaml "Add the encrypted podinfo-db Secret" < "$KEY_DIR/apps/podinfo/secret.yaml"

kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$KEY_DIR/age.agekey" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n gitea delete secret team-age-key --ignore-not-found
rm -rf "$KEY_DIR"

echo "[lab] Creating the Git credentials Secret fleet-auth..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops \
  --password=gitops-password

echo "[lab] Applying the Flux objects..."
kubectl apply -f "$MANIFESTS/sync.yaml"

flux reconcile source git fleet --timeout=3m || true
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=5m || true

echo "[lab] Creating a Receiver and a Gitea webhook that do not work together..."
kubectl -n flux-system create secret generic receiver-token \
  --from-literal=token=receiver-token-in-cluster --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$MANIFESTS/receiver.yaml"
for _ in $(seq 1 60); do
  HOOK_PATH="$(kubectl -n flux-system get receiver gitea-receiver -o jsonpath='{.status.webhookPath}' 2>/dev/null)"
  [ -n "$HOOK_PATH" ] && break
  sleep 2
done
gitea_call POST "$REPO_PATH/hooks" \
  "{\"type\":\"gitea\",\"active\":true,\"events\":[\"push\"],\"branch_filter\":\"*\",\"config\":{\"url\":\"http://webhook-receiver.flux-system.svc.cluster.local$HOOK_PATH\",\"content_type\":\"json\",\"secret\":\"an-older-webhook-secret\"}}" >/dev/null

echo "[lab] Starting state ready."
flux get sources git || true
flux get kustomizations || true
