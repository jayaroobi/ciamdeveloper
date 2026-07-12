#!/usr/bin/env bash
# ForgeOps minikube setup — commands from official quick-set-mini guide
# https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html
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

echo "==> ForgeOps repo: $FORGEOPS_REPO (tag $FORGEOPS_TAG)"
echo "==> FQDN: $FORGEOPS_FQDN | namespace: $FORGEOPS_NAMESPACE"

if [[ ! -d "$FORGEOPS_REPO/.git" ]]; then
  git clone https://github.com/ForgeRock/forgeops.git "$FORGEOPS_REPO"
fi

cd "$FORGEOPS_REPO"
git fetch --tags
git checkout "$FORGEOPS_TAG"

echo "==> Starting minikube (requires Docker)..."
minikube start --cpus=3 --memory=9g --disk-size=40g --cni=true \
  --kubernetes-version=stable --addons=ingress,volumesnapshots,metrics-server \
  --driver=docker

if ! grep -q "$FORGEOPS_FQDN" /etc/hosts 2>/dev/null; then
  echo "!! Add this line to /etc/hosts (sudo required):"
  echo "   127.0.0.1 $FORGEOPS_FQDN"
fi

if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi
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

echo ""
echo ""
echo "==> For full automated deploy, use: ./forgeops/scripts/deploy-full-stack.sh"
echo "==> Or manually:"
echo "    Terminal 2: sudo minikube tunnel"
echo "    Then: ./forgeops/scripts/deploy-full-stack.sh (or helm upgrade ...)"
echo ""
echo "Docs: docs/forgeops-full-stack-setup.md"
