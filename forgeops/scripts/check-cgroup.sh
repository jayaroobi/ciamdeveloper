#!/usr/bin/env bash
# Diagnose why minikube/ForgeOps may fail with cgroup memory errors
set -euo pipefail

echo "==> CIAM Lab — cgroup / environment check"
echo ""

echo "Memory (RAM):"
free -h | head -2
echo ""

CGROUP_TYPE="unknown"
SUBTREE=""
if [[ -f /sys/fs/cgroup/cgroup.type ]]; then
  CGROUP_TYPE=$(cat /sys/fs/cgroup/cgroup.type)
  SUBTREE=$(cat /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || echo "")
  echo "Cgroup root:"
  echo "  type:            $CGROUP_TYPE"
  echo "  controllers:     $(cat /sys/fs/cgroup/cgroup.controllers 2>/dev/null || echo n/a)"
  echo "  subtree_control: ${SUBTREE:-n/a}"
  echo ""
else
  echo "Cgroup root: /sys/fs/cgroup/cgroup.type missing (common on some WSL2 builds)"
  echo "  Controllers present: $(ls /sys/fs/cgroup 2>/dev/null | tr '\n' ' ')"
  echo ""
fi

if [[ -f /sys/fs/cgroup/docker/cgroup.type ]]; then
  echo "Docker cgroup:"
  echo "  type:            $(cat /sys/fs/cgroup/docker/cgroup.type)"
  echo "  subtree_control: $(cat /sys/fs/cgroup/docker/cgroup.subtree_control 2>/dev/null || echo n/a)"
  echo ""
fi

VIRT=$(systemd-detect-virt 2>/dev/null || echo "unknown")
echo "Virtualization: $VIRT"
echo ""

BLOCKED=0

if [[ "$CGROUP_TYPE" == *"threaded"* ]]; then
  echo "[BLOCKED] Root cgroup is '$CGROUP_TYPE'"
  echo "          Docker cannot apply --memory limits (minikube needs this)."
  BLOCKED=1
fi

# Only enforce memory-delegation check when cgroup v2 type file exists
if [[ -f /sys/fs/cgroup/cgroup.type && "$SUBTREE" != *"memory"* ]]; then
  echo "[BLOCKED] Memory controller NOT delegated to this environment"
  echo "          subtree_control: $SUBTREE"
  BLOCKED=1
fi

if [[ "$VIRT" == "docker" || "$VIRT" == "container" ]]; then
  echo "[INFO]    You are inside a container (Cursor workspace / dev container)"
  echo "          ForgeOps K8s will NOT work here — use a full VM or host OS."
  BLOCKED=1
fi

echo ""
if [[ $BLOCKED -eq 1 ]]; then
  echo "==> ForgeOps/minikube CANNOT run in this environment."
  echo ""
  echo "Fix options (pick one):"
  echo "  1. WSL2 Ubuntu + Docker Desktop (recommended on this laptop)"
  echo "  2. Multipass VM with Hyper-V driver (not VirtualBox)"
  echo "  3. Cloud VM — see docs/forgeops-cloud-vm.md"
  echo ""
  echo "What DOES work in Cursor Docker workspace:"
  echo "  ./forgeops/scripts/start-postgresql.sh"
  echo "  apps/saml-service-provider (npm start)"
  exit 1
else
  echo "==> Environment OK for minikube. Run: ./forgeops/scripts/setup-forgerock.sh"
fi
