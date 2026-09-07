#!/usr/bin/env bash
# Optional: deploy PingGateway (IG) — NOT included in default identity-platform chart
# See: https://github.com/ForgeRock/forgeops/tree/main/charts/ping-gateway
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/env.local"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

FORGEOPS_REPO="${FORGEOPS_REPO:-$HOME/forgeops}"
FORGEOPS_FQDN="${FORGEOPS_FQDN:-forgeops.example.com}"
FORGEOPS_NAMESPACE="${FORGEOPS_NAMESPACE:-my-namespace}"
FORGEOPS_ENV_NAME="${FORGEOPS_ENV_NAME:-my-env}"

echo "==> PingGateway is OPTIONAL and not in default identity-platform deploy."
echo "==> Deploying ping-gateway chart to namespace: $FORGEOPS_NAMESPACE"

cd "$FORGEOPS_REPO/bin"
# shellcheck source=/dev/null
source ../.venv/bin/activate

# Generate IG env if not exists
if [[ ! -f "../helm/${FORGEOPS_ENV_NAME}-ig/values.yaml" ]]; then
  ./forgeops env --env-name "${FORGEOPS_ENV_NAME}-ig" --fqdn "$FORGEOPS_FQDN" \
    --component ig --namespace "$FORGEOPS_NAMESPACE" 2>/dev/null || {
    echo "Creating IG values from ping-gateway chart defaults..."
    mkdir -p "../helm/${FORGEOPS_ENV_NAME}-ig"
    cp "../charts/ping-gateway/values.yaml" "../helm/${FORGEOPS_ENV_NAME}-ig/values.yaml"
  }
fi

VALUES_FILE="../helm/${FORGEOPS_ENV_NAME}-ig/values.yaml"
if [[ ! -f "$VALUES_FILE" ]]; then
  VALUES_FILE="../charts/ping-gateway/values.yaml"
fi

helm upgrade --install ping-gateway ping-gateway \
  --repo https://ForgeRock.github.io/forgeops/ \
  --namespace "$FORGEOPS_NAMESPACE" \
  --values "$VALUES_FILE"

kubectl get pods -n "$FORGEOPS_NAMESPACE" -l app.kubernetes.io/name=ping-gateway
echo "==> PingGateway deployed. Check ingress for IG URL."
