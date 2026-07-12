#!/usr/bin/env bash
# Verify ForgeOps identity-platform components are running
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/env.local"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

FORGEOPS_NAMESPACE="${FORGEOPS_NAMESPACE:-my-namespace}"
FORGEOPS_FQDN="${FORGEOPS_FQDN:-forgeops.example.com}"

echo "==> Namespace: $FORGEOPS_NAMESPACE"
echo ""
kubectl get pods -n "$FORGEOPS_NAMESPACE" -o wide
echo ""
kubectl get svc -n "$FORGEOPS_NAMESPACE"
echo ""
kubectl get ingress -n "$FORGEOPS_NAMESPACE" 2>/dev/null || true
echo ""

check_pod() {
  local label=$1
  local name=$2
  if kubectl get pods -n "$FORGEOPS_NAMESPACE" -l "$label" 2>/dev/null | grep -q Running; then
    echo "  [OK] $name"
  else
    echo "  [??] $name — check: kubectl get pods -n $FORGEOPS_NAMESPACE -l $label"
  fi
}

echo "==> Component checklist:"
check_pod "app.kubernetes.io/component=am" "PingAM"
check_pod "app.kubernetes.io/component=idm" "PingIDM"
check_pod "app.kubernetes.io/component=ds-idrepo" "PingDS idrepo (identity DB)"
check_pod "app.kubernetes.io/component=ds-cts" "PingDS cts (token store)"
check_pod "app.kubernetes.io/component=login-ui" "Login UI"
check_pod "app.kubernetes.io/component=admin-ui" "Admin UI"
check_pod "app.kubernetes.io/component=end-user-ui" "End-user UI"

echo ""
echo "==> Completed jobs:"
kubectl get jobs -n "$FORGEOPS_NAMESPACE" 2>/dev/null || true

echo ""
echo "==> URLs (requires minikube tunnel + /etc/hosts):"
echo "  Platform:  https://${FORGEOPS_FQDN}/platform"
echo "  AM:        https://${FORGEOPS_FQDN}/am"
echo "  IDM:       https://${FORGEOPS_FQDN}/admin"
echo "  End-user:  https://${FORGEOPS_FQDN}/enduser"
