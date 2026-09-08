#!/usr/bin/env bash
# WSL entrypoint for ForgeOps (Ping AM + IDM + PingDS).
# Called from setup-forgerock-wsl.ps1 so Windows PowerShell never embeds bash
# (PowerShell 5.1 cannot parse @" "@ here-strings in LF-ended .ps1 files).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [[ ! -f README.md ]]; then
  echo "Repo not found at $REPO_ROOT"
  echo "Clone to C:\\ciam first, then re-run from PowerShell or Ubuntu."
  exit 1
fi

# Strip CRLF so bash can run scripts checked out on Windows.
sed -i 's/\r$//' forgeops/scripts/*.sh forgeops/config/env.local 2>/dev/null || true
chmod +x forgeops/scripts/*.sh

# Docker Desktop WSL integration often works without the docker group;
# if docker is still blocked, retry the deploy via sg docker.
if ! docker info >/dev/null 2>&1; then
  if command -v sg >/dev/null 2>&1 && getent group docker >/dev/null 2>&1; then
    echo "Docker not usable yet; retrying via sg docker..."
    exec sg docker -c "$SCRIPT_DIR/setup-forgerock.sh"
  fi
fi

exec "$SCRIPT_DIR/setup-forgerock.sh"
