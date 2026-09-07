#!/usr/bin/env bash
# Ensure python3 + venv (ensurepip) are available on Ubuntu/Debian.
# Called from ForgeOps scripts before `python3 -m venv`.
set -euo pipefail

need_install=0
command -v python3 >/dev/null 2>&1 || need_install=1
python3 -c "import ensurepip" 2>/dev/null || need_install=1

if [[ "$need_install" -eq 1 ]]; then
  echo "[ensure-python-venv] Installing python3 / python3-venv / python3-pip..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq python3 python3-venv python3-pip python3.12-venv || \
    sudo apt-get install -y -qq python3 python3-venv python3-pip
fi

if ! python3 -c "import ensurepip" 2>/dev/null; then
  echo "[ensure-python-venv] ERROR: ensurepip still missing. Run: sudo apt-get install -y python3-venv" >&2
  exit 1
fi
