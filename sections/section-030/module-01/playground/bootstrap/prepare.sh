#!/usr/bin/env bash
# OS prep for the "Reconcile On Push With A Receiver" playground (`ats-097-playground-030-01`).
#
# Environment preparation only. There is no task and no grading.
# Install flux, sops and age, start Gitea (allowed to call private addresses), seed gitops/fleet with podinfo, install Flux and apply a GitRepository that polls only once an hour.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

FLUX_VERSION="2.9.6"
SOPS_VERSION="3.13.3"
AGE_VERSION="1.3.2"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Pin every version rather than accepting whatever happens to be on the
# machine: the flux CLI installs controllers of its own version, and the pages
# are written against these releases.
have_flux=""
command -v flux >/dev/null 2>&1 && \
  have_flux=$(flux version --client 2>/dev/null | awk '/flux:/{print $2}' | sed 's/^v//')
if [ "$have_flux" != "$FLUX_VERSION" ]; then
  echo "[playground] Downloading Flux CLI ${FLUX_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" flux
  install -m 0755 "$WORK/flux" "$BIN_DIR/flux"
fi

have_sops=""
command -v sops >/dev/null 2>&1 && \
  have_sops=$(sops --version 2>/dev/null | awk 'NR==1{print $2}')
if [ "$have_sops" != "$SOPS_VERSION" ]; then
  echo "[playground] Downloading SOPS ${SOPS_VERSION}..."
  curl -fsSL -o "$WORK/sops" \
    "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.${OS}.${ARCH}"
  install -m 0755 "$WORK/sops" "$BIN_DIR/sops"
fi

have_age=""
command -v age >/dev/null 2>&1 && have_age=$(age --version 2>/dev/null | sed 's/^v//')
if [ "$have_age" != "$AGE_VERSION" ] || ! command -v age-keygen >/dev/null 2>&1; then
  echo "[playground] Downloading age ${AGE_VERSION}..."
  curl -fsSL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-${OS}-${ARCH}.tar.gz" \
    | tar -xz -C "$WORK"
  install -m 0755 "$WORK/age/age" "$BIN_DIR/age"
  install -m 0755 "$WORK/age/age-keygen" "$BIN_DIR/age-keygen"
fi
flux version --client
sops --version | head -1
age --version

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done
MANIFESTS="$MANIFEST_DIR"

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

GIT_HOST="gitea.localtest.me"
GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
REPO="fleet"

echo "[playground] Applying Gitea and the tester pod..."
kubectl apply -f "$MANIFESTS/lab-start.yaml"
kubectl -n gitea rollout status deployment/gitea --timeout=300s
kubectl -n gitea rollout status deployment/tester --timeout=300s

# One Git address for the learner's machine and the cluster: gitea.localtest.me
# resolves to 127.0.0.1 on the machine (reached through a port-forward), and
# this CoreDNS block sends the same name to the Gitea Service in the cluster.
# The answer is rewritten back to the asked name: Go programs such as the Flux
# controllers ignore DNS answers whose name differs from the question.
if ! kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$GIT_HOST"; then
  echo "[playground] Adding the CoreDNS rewrite for ${GIT_HOST}..."
  COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex gitea\\.localtest\\.me gitea-http.gitea.svc.cluster.local"
        print "        answer name gitea-http\\.gitea\\.svc\\.cluster\\.local gitea.localtest.me"
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

echo "[playground] Creating the Gitea user ${GIT_USER} and the repository ${GIT_USER}/${REPO}..."
for _ in $(seq 1 30); do
  kubectl -n gitea exec deploy/gitea -- gitea admin user create \
    --username "$GIT_USER" --password "$GIT_PASSWORD" --email gitops@example.com \
    --admin --must-change-password=false >/dev/null 2>&1 && break
  gitea_call GET "/user" >/dev/null 2>&1 && break
  sleep 2
done
gitea_call GET "/repos/$GIT_USER/$REPO" >/dev/null 2>&1 || \
  gitea_call POST "/user/repos" "{\"name\":\"$REPO\",\"auto_init\":true,\"default_branch\":\"main\",\"private\":true}" >/dev/null

echo "[playground] Seeding the repository..."
if ! git_read_file apps/podinfo/kustomization.yaml >/dev/null 2>&1; then
  (cd "$MANIFESTS/repo" && find . -type f | sed 's|^\./||' | sort) | while read -r file; do
    git_put_file "$file" "Add $file" < "$MANIFESTS/repo/$file"
  done
fi

echo "[playground] Installing the Flux controllers..."
flux install
flux check

echo "[playground] Creating the Secret podinfo-db outside Git..."
kubectl create namespace podinfo --dry-run=client -o yaml | kubectl apply -f -
kubectl -n podinfo create secret generic podinfo-db \
  --from-literal=password=created-outside-git --dry-run=client -o yaml | kubectl apply -f -

echo "[playground] Creating the Git credentials Secret fleet-auth..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops \
  --password=gitops-password

echo "[playground] Applying the Flux objects..."
kubectl apply -f "$MANIFESTS/sync.yaml"

flux reconcile source git fleet --timeout=3m || true
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=5m || true

echo "[playground] Ready."
kubectl -n flux-system get pods
echo "[playground] Start the port-forward in a second terminal before you use git:"
echo "  kubectl -n gitea port-forward svc/gitea-http 3000:3000"
