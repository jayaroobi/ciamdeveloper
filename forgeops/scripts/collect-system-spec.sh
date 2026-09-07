#!/usr/bin/env bash
# Collect system specs — updates skill metadata reference
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker_info() {
  if docker info >/dev/null 2>&1; then
    docker info 2>/dev/null
  elif command -v sg >/dev/null && groups | grep -q docker; then
    sg docker -c 'docker info' 2>/dev/null
  else
    sg docker -c 'docker info' 2>/dev/null || true
  fi
}

docker_version_cmd() {
  if docker --version >/dev/null 2>&1; then
    docker --version 2>/dev/null
  else
    sg docker -c 'docker --version' 2>/dev/null || true
  fi
}

STORAGE=$(docker_info | grep 'Storage Driver' | awk '{print $3}' || echo n/a)
DVER=$(docker_version_cmd | awk '{print $3}' | tr -d , || echo not-installed)

echo "=== System spec snapshot $(date -Iseconds) ==="
echo ""
echo "physical_host_os: Windows  # confirm manually if changed"
echo "dev_environment: Cursor cloud workspace (Docker container)"
echo "workspace_os: $(. /etc/os-release && echo "$PRETTY_NAME")"
echo "workspace_kernel: $(uname -r)"
echo "cpu_cores: $(nproc)"
echo "cpu_model: $(lscpu 2>/dev/null | grep 'Model name' | cut -d: -f2 | xargs || echo unknown)"
echo "ram_total_gib: $(free -g | awk '/Mem:/ {print $2}')"
echo "ram_available_gib: $(free -g | awk '/Mem:/ {print $7}')"
echo "swap: $(free -h | awk '/Swap:/ {print $2}')"
echo "disk_total_gib: $(df -BG / | awk 'NR==2 {print $2}' | tr -d G)"
echo "disk_free_gib: $(df -BG / | awk 'NR==2 {print $4}' | tr -d G)"
echo "virtualization: $(systemd-detect-virt 2>/dev/null || echo unknown)"
echo "cgroup_type: $(cat /sys/fs/cgroup/cgroup.type)"
echo "cgroup_subtree_control: $(cat /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || echo n/a)"
echo "cgroup_memory_delegated: $(cat /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null | grep -q memory && echo true || echo false)"
echo "docker_version: ${DVER}"
echo "docker_storage_driver: ${STORAGE}"
echo "node_version: $(node --version 2>/dev/null || echo not-installed)"
echo "python_version: $(python3 --version 2>/dev/null | awk '{print $2}' || echo not-installed)"
echo "forgeops_runnable_in_workspace: $("$SCRIPT_DIR/check-cgroup.sh" >/dev/null 2>&1 && echo true || echo false)"
echo ""
echo "Run ./forgeops/scripts/check-cgroup.sh for full deployment guidance."
echo "Skill metadata: .cursor/skills/forgeops-ciam-lab/SKILL.md"
