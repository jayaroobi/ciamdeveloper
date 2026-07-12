#!/usr/bin/env bash
# Diagnose why minikube/ForgeOps may fail with cgroup memory errors
set -euo pipefail

echo "==> CIAM Lab — cgroup / environment check"
echo ""

echo "Memory (RAM):"
free -h | head -2
echo ""

echo "Cgroup root:"
echo "  type:           $(cat /sys/fs/cgroup/cgroup.type)"
echo "  controllers:    $(cat /sys/fs/cgroup/cgroup.controllers 2>/dev/null || echo n/a)"
echo "  subtree_control: $(cat /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || echo n/a)"
echo ""

if [[ -f /sys/fs/cgroup/docker/cgroup.type ]]; then
  echo "Docker cgroup:"
  echo "  type:           $(cat /sys/fs/cgroup/docker/cgroup.type)"
  echo "  subtree_control: $(cat /sys/fs/cgroup/docker/cgroup.subtree_control)"
  echo ""
fi

VIRT=$(systemd-detect-virt 2>/dev/null || echo "unknown")
echo "Virtualization: $VIRT"
echo ""

CGROUP_TYPE=$(cat /sys/fs/cgroup/cgroup.type)
SUBTREE=$(cat /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || echo "")

BLOCKED=0

if [[ "$CGROUP_TYPE" == *"threaded"* ]]; then
  echo "[BLOCKED] Root cgroup is '$CGROUP_TYPE'"
  echo "          Docker cannot apply --memory limits (minikube needs this)."
  BLOCKED=1
fi

if [[ "$SUBTREE" != *"memory"* ]]; then
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
  echo "  1. Full Ubuntu VM (Multipass/VirtualBox/Hyper-V) with 9GB+ RAM"
  echo "  2. Cloud VM (Oracle free tier / AWS / GCP) — see docs/forgeops-cloud-vm.md"
  echo "  3. Host OS terminal (NOT inside Cursor dev container) if you have bare metal Linux"
  echo ""
  echo "What DOES work here:"
  echo "  ./forgeops/scripts/start-postgresql.sh"
  echo "  apps/saml-service-provider (npm start)"
  exit 1
else
  echo "==> Environment OK for minikube. Run: ./forgeops/scripts/setup-today.sh"
fi
