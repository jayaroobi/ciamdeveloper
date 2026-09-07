#!/usr/bin/env bash
# Hands-on lab setup for Cursor cloud workspace
# ForgeOps AM/IDM/DS cannot run here — use WSL on Windows for that (see below).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log() { echo "[$(date +%H:%M:%S)] $*"; }

echo "=== CIAM hands-on lab (Cursor workspace) ==="
echo ""

# Environment check
if "$SCRIPT_DIR/check-cgroup.sh" >/dev/null 2>&1; then
  FORGEOPS_OK=1
else
  FORGEOPS_OK=0
fi

if [[ $FORGEOPS_OK -eq 0 ]]; then
  log "ForgeOps/minikube: NOT available in this Docker workspace"
  log "  → Deploy AM on Windows WSL: see docs/HANDS-ON.md"
else
  log "ForgeOps/minikube: environment OK — run ./forgeops/scripts/setup-forgerock.sh"
fi

echo ""
log "Step 1/3: PostgreSQL (native, no Docker)..."
"$SCRIPT_DIR/start-postgresql-native.sh"

echo ""
log "Step 2/3: SAML Service Provider..."
SP_DIR="$REPO_ROOT/apps/saml-service-provider"
cd "$SP_DIR"
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "DATABASE_URL=postgresql://ciam_app:ciam_lab_dev@127.0.0.1:5432/ciam_lab" >> .env
fi
npm install --silent
npm run generate-metadata

echo ""
log "Step 3/3: OAuth2/OIDC client app..."
OIDC_DIR="$REPO_ROOT/apps/oauth2-oidc-client"
if [[ -d "$OIDC_DIR" ]]; then
  cd "$OIDC_DIR"
  [[ -f .env ]] || cp .env.example .env 2>/dev/null || true
  npm install --silent 2>/dev/null || true
fi

echo ""
echo "=== Workspace lab ready ==="
echo ""
echo "What works HERE (no ForgeOps AM yet):"
echo "  • PostgreSQL + schema (login_audit, app_users)"
echo "  • SAML SP metadata generated"
echo "  • Code editing, docs, curriculum"
echo ""
echo "Start SAML SP (after AM is configured in WSL):"
echo "  cd apps/saml-service-provider && npm start"
echo "  → http://localhost:3000"
echo ""
echo "For Ping AM / IDM / PingDS (required for SSO hands-on):"
echo ""
echo "  On your Windows laptop (PowerShell):"
echo "    cd C:\\ciam"
echo "    git pull origin cursor/forgeops-ciam-career-lab-fe67"
echo "    .\\forgeops\\scripts\\setup-forgerock-wsl.ps1"
echo ""
echo "  Then Week 2 lab: labs/week-02-saml-sso/README.md"
echo ""
