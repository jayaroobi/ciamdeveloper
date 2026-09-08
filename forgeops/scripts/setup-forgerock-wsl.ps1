# Run ForgeOps setup inside WSL Ubuntu (Ping AM + IDM + PingDS)
# Called by setup-from-scratch.ps1 or run directly:
#   cd C:\ciam
#   .\forgeops\scripts\setup-forgerock-wsl.ps1
#
# Do not use @" "@ here-strings in this file. Windows PowerShell 5.1
# cannot parse them when the script has Unix (LF) line endings, and
# fails with: Unexpected token 'Repo' in expression or statement.

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

$winScript = Join-Path $RepoPath "forgeops\scripts\setup-forgerock-in-wsl.sh"
if (-not (Test-Path $winScript)) {
    Write-Host "Missing forgeops\scripts\setup-forgerock-in-wsl.sh" -ForegroundColor Red
    Write-Host "From Ubuntu run:"
    Write-Host "  cd /mnt/c/ciam"
    Write-Host "  ./forgeops/scripts/setup-forgerock.sh"
    exit 1
}

$wslScript = $WslRepo + '/forgeops/scripts/setup-forgerock-in-wsl.sh'

Write-Host ""
Write-Host "Installing tools + deploying AM/IDM/DS (45-60 min)..." -ForegroundColor Cyan
Write-Host ""
Write-Host "!! OPEN SECOND UBUNTU WINDOW NOW - run before pressing Enter when asked:" -ForegroundColor Yellow
Write-Host "     sudo minikube tunnel" -ForegroundColor White
Write-Host ""

# Call the bash file by path. Do not embed a bash script in this .ps1.
wsl -d $WslDistro -- bash $wslScript
exit $LASTEXITCODE
