#!/usr/bin/env bash
# Pushes a commit and confirms source-controller fetches it within a minute.
set -uo pipefail

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

before="$(git_head_sha)"
printf 'Receiver check at %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  | git_put_file docs/receiver-check.md "Check that a push reaches the cluster"
after="$(git_head_sha)"
if [ -z "$after" ] || [ "$after" = "$before" ]; then
  echo "FAIL: could not push a test commit to gitops/fleet."
  exit 1
fi
for _ in $(seq 1 30); do
  revision="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.revision}' 2>/dev/null)"
  case "$revision" in
    *"$after"*) echo "PASS: source-controller fetched the pushed commit ${after:0:12} within seconds."; exit 0 ;;
  esac
  sleep 2
done
echo "FAIL: 60 seconds after a push, the GitRepository fleet still holds '$revision', not ${after:0:12}."
echo "      With a one-hour interval, only the Receiver can make it fetch sooner."
exit 1
