#!/usr/bin/env bash
# Pre-flight check before ForgeOps + PostgreSQL deploy (run on your local machine)
set -uo pipefail

PASS=0
FAIL=0

check() {
  local name=$1
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [OK]   $name"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $name"
    FAIL=$((FAIL + 1))
  fi
}

echo "==> CIAM Lab pre-flight check"
echo ""

echo "-- Tools --"
check "docker" docker info
check "minikube" minikube version
check "kubectl" kubectl version --client
check "helm" helm version
check "kubens" kubens
check "python3" python3 --version
check "node" node --version
check "npm" npm --version
command -v psql >/dev/null 2>&1 && echo "  [OK]   psql (optional)" || echo "  [??]   psql — optional: sudo apt install postgresql-client"

echo ""
echo "-- Repo --"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
check "forgeops scripts" test -x "$REPO_ROOT/forgeops/scripts/deploy-full-stack.sh"
check "postgresql compose" test -f "$REPO_ROOT/infra/postgresql/docker-compose.yml"
check "SAML SP metadata" test -f "$REPO_ROOT/apps/saml-service-provider/metadata/sp-metadata.xml"

echo ""
echo "-- Config --"
if [[ -f "$REPO_ROOT/forgeops/config/env.local" ]]; then
  echo "  [OK]   forgeops/config/env.local"
  PASS=$((PASS + 1))
else
  echo "  [??]   forgeops/config/env.local — run: cp forgeops/config/env.example forgeops/config/env.local"
fi

if grep -q "forgeops.example.com" /etc/hosts 2>/dev/null; then
  echo "  [OK]   /etc/hosts has forgeops.example.com"
  PASS=$((PASS + 1))
else
  echo "  [??]   /etc/hosts — run: ./forgeops/scripts/add-hosts-entry.sh"
fi

echo ""
echo "==> Result: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  echo "Fix failures before deploy. See: labs/week-01-forgeops-deploy/README.md"
  exit 1
fi
echo "Ready to deploy."
