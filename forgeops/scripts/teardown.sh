#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/env.local"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

FORGEOPS_NAMESPACE="${FORGEOPS_NAMESPACE:-my-namespace}"

echo "==> Uninstalling identity-platform from namespace $FORGEOPS_NAMESPACE..."
helm uninstall identity-platform -n "$FORGEOPS_NAMESPACE" 2>/dev/null || true
kubectl delete namespace "$FORGEOPS_NAMESPACE" --ignore-not-found

echo "==> Stopping minikube..."
minikube stop

echo "Done. To delete the cluster entirely: minikube delete"
