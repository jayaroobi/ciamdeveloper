#!/usr/bin/env bash
# Install ForgeOps prerequisites on Ubuntu/Debian
# Based on: https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html
set -euo pipefail

echo "==> Installing Docker..."
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER" || true
  echo "!! Added $USER to docker group — log out/in or run: newgrp docker"
fi

echo "==> Installing kubectl..."
if ! command -v kubectl >/dev/null 2>&1; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl
fi

echo "==> Installing Helm..."
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  bash /tmp/get_helm.sh
  rm -f /tmp/get_helm.sh
fi

echo "==> Installing minikube..."
if ! command -v minikube >/dev/null 2>&1; then
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm -f minikube-linux-amd64
fi

echo "==> Installing kubens (kubectx package)..."
if ! command -v kubens >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq kubectx || {
    sudo curl -sLo /usr/local/bin/kubens https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
    sudo chmod +x /usr/local/bin/kubens
  }
fi

echo "==> Checking python3 + venv..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/ensure-python-venv.sh"
echo "python3-venv OK"

echo ""
echo "==> Versions:"
docker --version 2>/dev/null || echo "Docker: install complete — start daemon / re-login for group"
minikube version
kubectl version --client
helm version
python3 --version
echo ""
echo "Prerequisites installed. Next: cp forgeops/config/env.example forgeops/config/env.local"
echo "Then: ./forgeops/scripts/deploy-full-stack.sh"
