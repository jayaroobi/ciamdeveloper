# Run ForgeOps setup inside WSL Ubuntu (Ping AM + IDM + PingDS)
# Called by setup-from-scratch.ps1 or run directly:
#   cd C:\ciam
#   .\forgeops\scripts\setup-forgerock-wsl.ps1

param(
    [string]$RepoPath = "C:\ciam",
    [string]$WslDistro = "Ubuntu"
)

$ErrorActionPreference = "Stop"

# Convert C:\ciam -> /mnt/c/ciam for WSL
$WslRepo = ($RepoPath -replace '\\', '/')
if ($WslRepo -match '^([A-Za-z]):(.*)$') {
    $WslRepo = '/mnt/' + $Matches[1].ToLower() + $Matches[2]
}

Write-Host "=== ForgeOps via WSL ($WslDistro) ===" -ForegroundColor Cyan
Write-Host "Repo (WSL): $WslRepo" -ForegroundColor Gray
Write-Host ""

# Ensure Docker Desktop is up (WSL uses it)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
            Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 15
        }
    } catch { }
}

Write-Host "Checking WSL $WslDistro..." -ForegroundColor Cyan
wsl -d $WslDistro -- echo "WSL OK"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "WSL $WslDistro is not responding. Try:" -ForegroundColor Red
    Write-Host "  wsl --shutdown"
    Write-Host "  wsl -d $WslDistro"
    Write-Host "Or run full setup: .\forgeops\scripts\setup-from-scratch.ps1"
    exit 1
}

# Verify docker works inside WSL (Docker Desktop integration)
$dockerCheck = wsl -d $WslDistro -- bash -lc "docker info >/dev/null 2>&1 && echo OK || echo FAIL"
if ($dockerCheck -notmatch "OK") {
    Write-Host ""
    Write-Host "Docker not available inside WSL." -ForegroundColor Red
    Write-Host "  1. Start Docker Desktop on Windows"
    Write-Host "  2. Docker Desktop -> Settings -> Resources -> WSL Integration -> enable $WslDistro"
    Write-Host "  3. Re-run this script"
    exit 1
}
Write-Host "Docker OK inside WSL" -ForegroundColor Green

$bash = @"
set -euo pipefail
cd '$WslRepo'
if [[ ! -f README.md ]]; then
  echo "Repo not found at $WslRepo - clone to $RepoPath first"
  exit 1
fi
sed -i 's/\r$//' forgeops/scripts/*.sh forgeops/config/env.local 2>/dev/null || true
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/check-cgroup.sh
./forgeops/scripts/install-prerequisites-ubuntu.sh
# Docker Desktop: group may not apply - use sg or sudo-less docker if integration works
if ! docker info >/dev/null 2>&1; then
  echo "Trying newgrp docker..."
  exec sg docker -c './forgeops/scripts/setup-forgerock.sh'
fi
./forgeops/scripts/setup-forgerock.sh
"@

Write-Host ""
Write-Host "Installing tools + deploying AM/IDM/DS (45-60 min)..." -ForegroundColor Cyan
Write-Host ""
Write-Host "!! OPEN SECOND UBUNTU WINDOW NOW - run before pressing Enter when asked:" -ForegroundColor Yellow
Write-Host "     sudo minikube tunnel" -ForegroundColor White
Write-Host ""

wsl -d $WslDistro -- bash -lc $bash
exit $LASTEXITCODE
