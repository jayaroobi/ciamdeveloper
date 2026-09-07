#!/usr/bin/env bash
# Verify PostgreSQL connectivity and schema
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PG_DIR="${SCRIPT_DIR}/../../infra/postgresql"

cd "$PG_DIR"
# shellcheck source=/dev/null
source .env 2>/dev/null || source .env.example

export PGPASSWORD="${POSTGRES_PASSWORD:-ciam_lab_dev}"

echo "==> Checking PostgreSQL on localhost:${POSTGRES_PORT:-5432}..."
psql "postgresql://${POSTGRES_USER:-ciam_app}@localhost:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-ciam_lab}" \
  -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY 1;"

echo ""
psql "postgresql://${POSTGRES_USER:-ciam_app}@localhost:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-ciam_lab}" \
  -c "SELECT client_id, purpose FROM service_accounts LIMIT 5;"

echo ""
echo "[OK] PostgreSQL lab database is reachable."
