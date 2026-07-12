#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/env.local"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

FORGEOPS_FQDN="${FORGEOPS_FQDN:-forgeops.example.com}"
ENTRY="127.0.0.1 ${FORGEOPS_FQDN}"

if grep -q "$FORGEOPS_FQDN" /etc/hosts 2>/dev/null; then
  echo "Hosts entry already exists for $FORGEOPS_FQDN"
  exit 0
fi

echo "Adding: $ENTRY"
echo "$ENTRY" | sudo tee -a /etc/hosts
echo "Done."
