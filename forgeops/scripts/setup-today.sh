#!/usr/bin/env bash
# One-shot ForgeOps + PostgreSQL setup for local machine (Sohar lab)
# Run from repo root: ./forgeops/scripts/setup-today.sh 2>&1 | tee setup-today.log
#
# Official: https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="${REPO_ROOT}/setup-today.log"
FORGEOPS_REPO="${FORGEOPS_REPO:-$HOME/forgeops}"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"; }

log "=== CIAM Lab — full setup started ==="
log "Repo: $REPO_ROOT"

# ForgeRock-only mode: skip PostgreSQL (original plan focus)
FORGEROCK_ONLY="${FORGEROCK_ONLY:-0}"
if [[ "$FORGEROCK_ONLY" == "1" ]]; then
  exec "$SCRIPT_DIR/setup-forgerock.sh"
fi

# Block if cgroup prevents minikube (Cursor Docker workspace)
if [[ -f "$SCRIPT_DIR/check-cgroup.sh" ]] && ! "$SCRIPT_DIR/check-cgroup.sh" >/dev/null 2>&1; then
  log "ForgeRock/minikube blocked in this environment."
  log "Windows: .\\forgeops\\scripts\\windows-forgerock.ps1"
  log "Or: FORGEROCK_ONLY=1 ./forgeops/scripts/setup-forgerock.sh  (inside Multipass/WSL2 VM)"
  exit 1
fi

# --- Config ---
if [[ ! -f "$REPO_ROOT/forgeops/config/env.local" ]]; then
  cp "$REPO_ROOT/forgeops/config/env.example" "$REPO_ROOT/forgeops/config/env.local"
  log "Created forgeops/config/env.local"
fi
# shellcheck source=/dev/null
source "$REPO_ROOT/forgeops/config/env.local"

# --- Pre-flight ---
log "Step 1/8: Pre-flight check..."
"$SCRIPT_DIR/check-prerequisites.sh" || {
  log "Pre-flight failed. Run: ./forgeops/scripts/install-prerequisites-ubuntu.sh"
  exit 1
}

# --- Hosts ---
if ! grep -q "${FORGEOPS_FQDN:-forgeops.example.com}" /etc/hosts 2>/dev/null; then
  log "Step 2/8: Adding hosts entry (sudo)..."
  "$SCRIPT_DIR/add-hosts-entry.sh"
else
  log "Step 2/8: Hosts entry OK"
fi

# --- PostgreSQL ---
log "Step 3/8: Starting PostgreSQL..."
"$SCRIPT_DIR/start-postgresql.sh"
"$SCRIPT_DIR/verify-postgresql.sh"

# --- Clone ForgeOps ---
log "Step 4/8: Clone/checkout ForgeOps tag ${FORGEOPS_TAG:-2026.2.1}..."
if [[ ! -d "$FORGEOPS_REPO/.git" ]]; then
  git clone https://github.com/ForgeRock/forgeops.git "$FORGEOPS_REPO"
fi
cd "$FORGEOPS_REPO"
git fetch --tags -q
git checkout "${FORGEOPS_TAG:-2026.2.1}"

# --- Minikube ---
log "Step 5/8: Starting minikube (10-15 min first time)..."
minikube status >/dev/null 2>&1 || minikube start --cpus=3 --memory=9g --disk-size=40g --cni=true \
  --kubernetes-version=stable --addons=ingress,volumesnapshots,metrics-server \
  --driver=docker

# --- Python venv + forgeops env ---
log "Step 6/8: Configuring ForgeOps environment..."
[[ -d .venv ]] || python3 -m venv .venv
# shellcheck source=/dev/null
source .venv/bin/activate
./bin/forgeops configure

kubectl apply -f etc/resources/selfsigned-issuer.yaml
cd bin
./forgeops env --env-name "${FORGEOPS_ENV_NAME:-my-env}" \
  --fqdn "${FORGEOPS_FQDN:-forgeops.example.com}" \
  --cluster-issuer "${FORGEOPS_CLUSTER_ISSUER:-default-issuer}" --single-instance

kubectl create namespace "${FORGEOPS_NAMESPACE:-my-namespace}" 2>/dev/null || true
kubens "${FORGEOPS_NAMESPACE:-my-namespace}"
./forgeops prereqs
kubectl apply -f ../etc/resources/minikube-fast-storage-class.yaml
./forgeops env --env-name "${FORGEOPS_ENV_NAME:-my-env}" --namespace "${FORGEOPS_NAMESPACE:-my-namespace}"

# --- Minikube tunnel check ---
if ! pgrep -f "minikube tunnel" >/dev/null 2>&1; then
  log ""
  log "!! IMPORTANT: Open a SECOND terminal and run:"
  log "   sudo minikube tunnel"
  log ""
  read -r -p "Press Enter after minikube tunnel is running..." _
fi

# --- Helm deploy ---
log "Step 7/8: Deploying identity-platform (AM + IDM + DS) — 15-25 min..."
helm upgrade --install identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops/ \
  --namespace "${FORGEOPS_NAMESPACE:-my-namespace}" \
  --values "../helm/${FORGEOPS_ENV_NAME:-my-env}/values.yaml"

log "Waiting for pods..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=identity-platform \
  --timeout=1800s -n "${FORGEOPS_NAMESPACE:-my-namespace}" 2>/dev/null || true

# --- Verify + credentials ---
log "Step 8/8: Verify stack..."
"$SCRIPT_DIR/verify-stack.sh" | tee -a "$LOG_FILE"

CREDS_FILE="${REPO_ROOT}/forgeops/CREDENTIALS.local"
{
  echo "# Generated $(date) — DO NOT COMMIT"
  echo "PLATFORM_URL=https://${FORGEOPS_FQDN:-forgeops.example.com}/platform"
  echo "AM_URL=https://${FORGEOPS_FQDN:-forgeops.example.com}/am"
  echo "IDM_URL=https://${FORGEOPS_FQDN:-forgeops.example.com}/admin"
  echo "POSTGRES_URL=postgresql://ciam_app:ciam_lab_dev@localhost:5432/ciam_lab"
  echo ""
  ./forgeops info | grep amadmin || ./forgeops info
} | tee "$CREDS_FILE"

log ""
log "=== SETUP COMPLETE ==="
log "Credentials saved: $CREDS_FILE"
log "Open: https://${FORGEOPS_FQDN:-forgeops.example.com}/platform"
log "Next: labs/week-02-saml-sso/README.md"
