# Run ForgeOps setup inside WSL Ubuntu (not native PowerShell/bash).
# Usage from PowerShell:
#   cd C:\ciam
#   .\forgeops\scripts\setup-forgerock-wsl.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== ForgeOps via WSL Ubuntu ===" -ForegroundColor Cyan
Write-Host "This must run Linux scripts inside WSL — not in Windows PowerShell." -ForegroundColor Yellow
Write-Host ""

# Ensure Docker Desktop is up (WSL uses it)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
            Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 8
        }
    } catch { }
}

Write-Host "Checking WSL Ubuntu..." -ForegroundColor Cyan
wsl -d Ubuntu -- echo "WSL Ubuntu OK"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "WSL Ubuntu is not responding. Try:" -ForegroundColor Red
    Write-Host "  wsl --shutdown"
    Write-Host "  wsl -d Ubuntu"
    Write-Host "Then re-run this script."
    exit 1
}

$bash = @'
set -euo pipefail
cd /mnt/c/ciam
sed -i "s/\r$//" forgeops/scripts/*.sh
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/check-cgroup.sh
./forgeops/scripts/install-prerequisites-ubuntu.sh
./forgeops/scripts/setup-forgerock.sh
'@

Write-Host ""
Write-Host "Running install + ForgeOps deploy inside WSL (45-60 min)..." -ForegroundColor Cyan
Write-Host "When prompted for minikube tunnel, open ANOTHER Ubuntu window and run:" -ForegroundColor Yellow
Write-Host "  sudo minikube tunnel" -ForegroundColor White
Write-Host ""

wsl -d Ubuntu -- bash -lc $bash
exit $LASTEXITCODE
