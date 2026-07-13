#!/usr/bin/env bash
# Original ForgeOps plan — Ping AM + IDM + PingDS via minikube
# Official: https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html
#
# Run on: Ubuntu VM (Multipass/WSL2) or bare Linux — NOT Cursor Docker workspace
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FORGEOPS_REPO="${FORGEOPS_REPO:-$HOME/forgeops}"
FORGEOPS_TAG="${FORGEOPS_TAG:-2026.2.1}"
FORGEOPS_FQDN="${FORGEOPS_FQDN:-forgeops.example.com}"
FORGEOPS_ENV_NAME="${FORGEOPS_ENV_NAME:-my-env}"
FORGEOPS_NAMESPACE="${FORGEOPS_NAMESPACE:-my-namespace}"
FORGEOPS_CLUSTER_ISSUER="${FORGEOPS_CLUSTER_ISSUER:-default-issuer}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

log "=== ForgeRock / ForgeOps — original plan deploy ==="

# Block Cursor Docker workspace
if [[ -f /sys/fs/cgroup/cgroup.type ]] && grep -q threaded /sys/fs/cgroup/cgroup.type; then
  if [[ "$(systemd-detect-virt 2>/dev/null)" == "docker" ]]; then
    log "ERROR: Cursor Docker workspace — ForgeRock cannot run here."
    log "Run on Windows Multipass VM: see docs/forgeops-windows-setup.md"
    log "  PowerShell: .\\forgeops\\scripts\\windows-forgerock.ps1"
    exit 1
  fi
fi

if [[ -f "$SCRIPT_DIR/check-cgroup.sh" ]]; then
  "$SCRIPT_DIR/check-cgroup.sh" || exit 1
fi

# Load config if present (strip Windows CRLF so WSL bash can source it)
if [[ -f "$REPO_ROOT/forgeops/config/env.local" ]]; then
  # shellcheck source=/dev/null
  source <(sed 's/\r$//' "$REPO_ROOT/forgeops/config/env.local")
fi

log "Step 1/7: Install prerequisites..."
"$SCRIPT_DIR/install-prerequisites-ubuntu.sh"

log "Step 2/7: Hosts entry..."
if ! grep -q "$FORGEOPS_FQDN" /etc/hosts 2>/dev/null; then
  echo "127.0.0.1 $FORGEOPS_FQDN" | sudo tee -a /etc/hosts
fi

log "Step 3/7: Clone ForgeOps $FORGEOPS_TAG..."
if [[ ! -d "$FORGEOPS_REPO/.git" ]]; then
  git clone https://github.com/ForgeRock/forgeops.git "$FORGEOPS_REPO"
fi
cd "$FORGEOPS_REPO"
git fetch --tags -q
git checkout "$FORGEOPS_TAG"

log "Step 4/7: Start minikube (official profile: 3 CPU, 9G RAM, 40G disk)..."
if ! groups | grep -q docker; then
  log "Run: newgrp docker   (or log out/in after install-prerequisites)"
  exit 1
fi
minikube status >/dev/null 2>&1 || minikube start --cpus=3 --memory=9g --disk-size=40g --cni=true \
  --kubernetes-version=stable --addons=ingress,volumesnapshots,metrics-server \
  --driver=docker

log "Step 5/7: Configure ForgeOps environment..."
[[ -d .venv ]] || python3 -m venv .venv
# shellcheck source=/dev/null
source .venv/bin/activate
./bin/forgeops configure

kubectl apply -f etc/resources/selfsigned-issuer.yaml
cd bin
./forgeops env --env-name "$FORGEOPS_ENV_NAME" --fqdn "$FORGEOPS_FQDN" \
  --cluster-issuer "$FORGEOPS_CLUSTER_ISSUER" --single-instance

kubectl create namespace "$FORGEOPS_NAMESPACE" 2>/dev/null || true
kubens "$FORGEOPS_NAMESPACE"
./forgeops prereqs
kubectl apply -f ../etc/resources/minikube-fast-storage-class.yaml
./forgeops env --env-name "$FORGEOPS_ENV_NAME" --namespace "$FORGEOPS_NAMESPACE"

if ! pgrep -f "minikube tunnel" >/dev/null 2>&1; then
  log ""
  log "!! Open a SECOND terminal and run:  sudo minikube tunnel"
  log ""
  read -r -p "Press Enter after minikube tunnel is running..." _
fi

log "Step 6/7: Helm deploy identity-platform (AM + IDM + DS-idrepo + DS-cts)..."
helm upgrade --install identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops/ \
  --namespace "$FORGEOPS_NAMESPACE" \
  --values "../helm/$FORGEOPS_ENV_NAME/values.yaml"

log "Waiting for pods (15-25 min first time)..."
kubectl get pods -n "$FORGEOPS_NAMESPACE" -w &
WATCH_PID=$!
sleep 300
kill $WATCH_PID 2>/dev/null || true

log "Step 7/7: Verify + save credentials..."
kubectl get pods -n "$FORGEOPS_NAMESPACE"
CREDS="${REPO_ROOT}/forgeops/CREDENTIALS.local"
{
  echo "# ForgeRock credentials — $(date)"
  echo "PLATFORM=https://${FORGEOPS_FQDN}/platform"
  echo "AM=https://${FORGEOPS_FQDN}/am"
  echo "IDM=https://${FORGEOPS_FQDN}/admin"
  echo ""
  ./forgeops info | grep amadmin || ./forgeops info
} | tee "$CREDS"

log ""
log "=== FORGEROCK IS UP ==="
log "Open: https://${FORGEOPS_FQDN}/platform"
log "Login: amadmin / password above"
log "Credentials: $CREDS"
