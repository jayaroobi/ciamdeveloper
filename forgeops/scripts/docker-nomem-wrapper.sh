#!/usr/bin/env bash
# Optional: wrap docker to strip --memory/--cpus for nested VM environments
# Usage: export PATH="$(dirname "$0"):$PATH" && ln -sf /usr/bin/docker "$(dirname "$0")/docker.real"
# Only use if minikube fails with cgroup threaded mode errors.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL="${DIR}/docker.real"
[[ -x "$REAL" ]] || REAL="/usr/bin/docker"
args=(); skip=0
for arg in "$@"; do
  if (( skip > 0 )); then ((skip--)); continue; fi
  case "$arg" in
    --memory|--memory-swap|--cpus) skip=1; continue ;;
    --memory=*|--memory-swap=*|--cpus=*) continue ;;
  esac
  args+=("$arg")
done
exec "$REAL" "${args[@]}"
