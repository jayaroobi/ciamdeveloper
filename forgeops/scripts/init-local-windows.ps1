# PowerShell — initialize local files for Windows (C:\ciam)
# Run once after git clone:
#   cd C:\ciam
#   .\forgeops\scripts\init-local-windows.ps1

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path "$RepoRoot\README.md")) {
    $RepoRoot = Get-Location
}

Write-Host "Repo root: $RepoRoot" -ForegroundColor Cyan

# 1. Copy Windows env template (reference file — env.local is gitignored)
$Template = "$RepoRoot\forgeops\config\windows.env.template"
$LocalEnv = "$RepoRoot\forgeops\config\env.local"
if (-not (Test-Path $LocalEnv)) {
    Copy-Item $Template $LocalEnv
    Write-Host "Created forgeops/config/env.local" -ForegroundColor Green
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
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
Write-Host "  cd $RepoRoot"
Write-Host "  .\forgeops\scripts\windows-forgerock.ps1"
