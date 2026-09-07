#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PG_DIR="${SCRIPT_DIR}/../../infra/postgresql"

cd "$PG_DIR"
docker compose down
echo "PostgreSQL stopped. Data volume preserved (ciam_lab_pgdata)."
