#!/usr/bin/env bash
# Start separate PostgreSQL for CIAM lab application data
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PG_DIR="${SCRIPT_DIR}/../../infra/postgresql"

cd "$PG_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created $PG_DIR/.env from example"
fi

# shellcheck source=/dev/null
source .env

docker compose up -d postgresql

echo "Waiting for PostgreSQL..."
for i in $(seq 1 30); do
  if docker compose exec -T postgresql pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo ""
echo "PostgreSQL is running."
echo "  Host:     localhost"
echo "  Port:     ${POSTGRES_PORT:-5432}"
echo "  Database: ${POSTGRES_DB:-ciam_lab}"
echo "  User:     ${POSTGRES_USER:-ciam_app}"
echo "  URL:      postgresql://${POSTGRES_USER:-ciam_app}:<password>@localhost:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-ciam_lab}"
echo ""
echo "Connect: psql \"postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}\""
echo "Optional pgAdmin: docker compose --profile admin up -d  → http://localhost:${PGADMIN_PORT:-5050}"
echo "Stop: ${SCRIPT_DIR}/stop-postgresql.sh"
