# Create C:\ciam on a new Windows laptop (folder does not exist yet).
#
# Run in PowerShell from C:\  — do NOT cd into C:\ciam first.
#
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   cd C:\
#   irm https://raw.githubusercontent.com/jayaroobi/ciamdeveloper/cursor/forgeops-ciam-career-lab-fe67/forgeops/scripts/create-ciam-folder.ps1 | iex
#
# Or if you already have this file:
#   .\create-ciam-folder.ps1

$ErrorActionPreference = "Stop"
$RepoPath = "C:\ciam"
$RepoUrl = "https://github.com/jayaroobi/ciamdeveloper.git"
$Branch = "cursor/forgeops-ciam-career-lab-fe67"

Write-Host "Creating lab folder: $RepoPath" -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing Git..." -ForegroundColor Yellow
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Install Git from https://git-scm.com/download/win then re-run." -ForegroundColor Red
        exit 1
    }
    winget install Git.Git --accept-package-agreements --accept-source-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

if (Test-Path "$RepoPath\.git") {
    Write-Host "$RepoPath already exists. Updating..." -ForegroundColor Yellow
    Set-Location $RepoPath
    git fetch origin
    git checkout $Branch
    git pull origin $Branch
} elseif (Test-Path $RepoPath) {
    Write-Host "$RepoPath exists but is not a git repo. Remove it or pick another path." -ForegroundColor Red
    Write-Host "  Remove-Item -Recurse -Force $RepoPath"
    exit 1
} else {
    Set-Location C:\
    git clone $RepoUrl $RepoPath
    Set-Location $RepoPath
    git checkout $Branch
}

Write-Host ""
Write-Host "OK: $RepoPath is ready." -ForegroundColor Green
Get-ChildItem $RepoPath | Select-Object -First 8 Name | ForEach-Object { Write-Host "  $($_.Name)" }
Write-Host ""
Write-Host "Next:" -ForegroundColor Cyan
Write-Host "  cd $RepoPath"
Write-Host "  .\forgeops\scripts\setup-from-scratch.ps1"
