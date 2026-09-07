#!/usr/bin/env bash
# Start PostgreSQL natively (no Docker) — for Cursor cloud workspace
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCHEMA="$REPO_ROOT/infra/postgresql/init/01-ciam-lab-schema.sql"

DB_NAME="${POSTGRES_DB:-ciam_lab}"
DB_USER="${POSTGRES_USER:-ciam_app}"
DB_PASS="${POSTGRES_PASSWORD:-ciam_lab_dev}"
DB_PORT="${POSTGRES_PORT:-5432}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

if ! command -v psql >/dev/null 2>&1; then
  log "Installing PostgreSQL server..."
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq postgresql postgresql-client
fi

# Ensure cluster is running
if command -v pg_ctlcluster >/dev/null 2>&1; then
  sudo pg_ctlcluster "$(ls /etc/postgresql/ | head -1)" main start 2>/dev/null || true
else
  sudo service postgresql start 2>/dev/null || sudo systemctl start postgresql
fi

log "Creating role and database (if needed)..."

sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\gexec
SQL

# Allow local password auth for lab user
PG_HBA="$(sudo -u postgres psql -tAc "SHOW hba_file;" | tr -d '[:space:]')"
if [[ -f "$PG_HBA" ]] && ! grep -q "ciam_lab_local" "$PG_HBA" 2>/dev/null; then
  echo "host ${DB_NAME} ${DB_USER} 127.0.0.1/32 scram-sha-256 # ciam_lab_local" | sudo tee -a "$PG_HBA" >/dev/null
  sudo service postgresql reload 2>/dev/null || sudo systemctl reload postgresql
fi

export PGPASSWORD="$DB_PASS"
psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -f "$SCHEMA"

echo ""
echo "PostgreSQL (native) is running."
echo "  URL: postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:${DB_PORT}/${DB_NAME}"
echo "  Test: psql \"postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:${DB_PORT}/${DB_NAME}\" -c '\\dt'"
