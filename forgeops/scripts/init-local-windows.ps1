# PowerShell - initialize local files for Windows (C:\ciam)
# Run once after git clone:
#   cd C:\ciam
#   .\forgeops\scripts\init-local-windows.ps1

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path "$RepoRoot\README.md")) {
    $RepoRoot = Get-Location
}

Write-Host "Repo root: $RepoRoot" -ForegroundColor Cyan

# 1. Bash-safe env for WSL (env.example), plus Windows path reference
$BashTemplate = "$RepoRoot\forgeops\config\env.example"
$LocalEnv = "$RepoRoot\forgeops\config\env.local"
if (-not (Test-Path $LocalEnv)) {
    Copy-Item $BashTemplate $LocalEnv
    Write-Host "Created forgeops/config/env.local (from env.example)" -ForegroundColor Green
} else {
    Write-Host "forgeops/config/env.local already exists" -ForegroundColor Yellow
}

# 2. Save local path reference
$LocalPathFile = "$RepoRoot\forgeops\config\local-path.txt"
@(
    "windows_repo=$RepoRoot"
    "hostname=$env:COMPUTERNAME"
    "updated=$(Get-Date -Format o)"
) | Set-Content $LocalPathFile
Write-Host "Updated forgeops/config/local-path.txt" -ForegroundColor Green

# 3. Execution policy hint
Write-Host ""
Write-Host "Next steps (new laptop - AM + IDM via WSL2):" -ForegroundColor Cyan
Write-Host "  1. Install WSL2 Ubuntu + Docker Desktop (see docs/new-laptop-setup.md)"
Write-Host "  2. Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
Write-Host "  3. cd $RepoRoot"
Write-Host "  4. .\forgeops\scripts\setup-forgerock-wsl.ps1"
Write-Host ""
Write-Host "Full guide: docs/new-laptop-setup.md"
