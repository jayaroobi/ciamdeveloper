#!/usr/bin/env bash
# Deploy full ForgeOps identity-platform stack (AM, IDM, DS-idrepo, DS-cts, UIs)
# Official guide: https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/env.local"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

FORGEOPS_REPO="${FORGEOPS_REPO:-$HOME/forgeops}"
FORGEOPS_TAG="${FORGEOPS_TAG:-2026.2.1}"
FORGEOPS_FQDN="${FORGEOPS_FQDN:-forgeops.example.com}"
FORGEOPS_ENV_NAME="${FORGEOPS_ENV_NAME:-my-env}"
FORGEOPS_NAMESPACE="${FORGEOPS_NAMESPACE:-my-namespace}"
FORGEOPS_CLUSTER_ISSUER="${FORGEOPS_CLUSTER_ISSUER:-default-issuer}"

log() { echo "==> $*"; }

log "ForgeOps full stack deployment"
log "Repo: $FORGEOPS_REPO | Tag: $FORGEOPS_TAG"
log "FQDN: $FORGEOPS_FQDN | Namespace: $FORGEOPS_NAMESPACE"

if [[ ! -d "$FORGEOPS_REPO/.git" ]]; then
  git clone https://github.com/ForgeRock/forgeops.git "$FORGEOPS_REPO"
fi

cd "$FORGEOPS_REPO"
git fetch --tags -q
git checkout "$FORGEOPS_TAG"

log "Starting minikube..."
minikube start --cpus=3 --memory=9g --disk-size=40g --cni=true \
  --kubernetes-version=stable --addons=ingress,volumesnapshots,metrics-server \
  --driver=docker

if ! grep -q "$FORGEOPS_FQDN" /etc/hosts 2>/dev/null; then
  log "Add to /etc/hosts: 127.0.0.1 $FORGEOPS_FQDN"
  log "Or run: sudo ${SCRIPT_DIR}/add-hosts-entry.sh"
fi

if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi
# shellcheck source=/dev/null
source .venv/bin/activate
./bin/forgeops configure

log "Applying cluster issuer..."
kubectl apply -f etc/resources/selfsigned-issuer.yaml

cd bin
./forgeops env --env-name "$FORGEOPS_ENV_NAME" --fqdn "$FORGEOPS_FQDN" \
  --cluster-issuer "$FORGEOPS_CLUSTER_ISSUER" --single-instance

kubectl create namespace "$FORGEOPS_NAMESPACE" 2>/dev/null || true
kubens "$FORGEOPS_NAMESPACE"

log "Installing prereqs (cert-manager, ingress-nginx)..."
./forgeops prereqs

kubectl apply -f ../etc/resources/minikube-fast-storage-class.yaml

./forgeops env --env-name "$FORGEOPS_ENV_NAME" --namespace "$FORGEOPS_NAMESPACE"

if ! pgrep -f "minikube tunnel" >/dev/null 2>&1; then
  log "WARNING: minikube tunnel is NOT running."
  log "Open a second terminal and run: sudo minikube tunnel"
  read -r -p "Press Enter after tunnel is started (or Ctrl+C to abort)..." _
fi

log "Helm install identity-platform (AM + IDM + DS + UIs)..."
helm upgrade --install identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops/ \
  --namespace "$FORGEOPS_NAMESPACE" \
  --values "../helm/${FORGEOPS_ENV_NAME}/values.yaml"

log "Waiting for pods (this can take 10-20 minutes on first run)..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=identity-platform \
  --timeout=1200s -n "$FORGEOPS_NAMESPACE" 2>/dev/null || true

kubectl get pods -n "$FORGEOPS_NAMESPACE"

log "Admin credentials:"
./forgeops info | grep amadmin || ./forgeops info

echo ""
log "Stack deployed. Open: https://${FORGEOPS_FQDN}/platform"
log "Verify: ${SCRIPT_DIR}/verify-stack.sh"
log "Optional IG: ${SCRIPT_DIR}/deploy-ping-gateway.sh"
log "SAML lab: docs/saml-lab-am-as-idp.md"
