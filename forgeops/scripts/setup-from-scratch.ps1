# ForgeRock AM + IDM — complete from-scratch setup (new Windows laptop)
#
# Run in PowerShell (Admin recommended for WSL install + hosts file):
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   irm https://raw.githubusercontent.com/jayaroobi/ciamdeveloper/cursor/forgeops-ciam-career-lab-fe67/forgeops/scripts/setup-from-scratch.ps1 | iex
#
# Or after git clone:
#   cd C:\ciam
#   .\forgeops\scripts\setup-from-scratch.ps1

param(
    [string]$RepoPath = "C:\ciam",
    [string]$Branch = "cursor/forgeops-ciam-career-lab-fe67",
    [string]$WslDistro = "Ubuntu",
    [switch]$SkipPrereqs,
    [switch]$SkipClone,
    [switch]$DeployOnly
)

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/jayaroobi/ciamdeveloper.git"
$Fqdn = "forgeops.example.com"

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = [Security.Principal.WindowsPrincipal]$id
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Step([string]$Num, [string]$Msg) {
    Write-Host ""
    Write-Host "=== Step $Num — $Msg ===" -ForegroundColor Cyan
}

function Ensure-HostsEntry {
    param([string]$HostName = $Fqdn)
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $content = Get-Content $hostsPath -Raw
    if ($content -match [regex]::Escape($HostName)) {
        Write-Host "Hosts file already has $HostName" -ForegroundColor Green
        return
    }
    if (-not (Test-Admin)) {
        Write-Host "Add manually (Admin Notepad): 127.0.0.1  $HostName" -ForegroundColor Yellow
        Write-Host "  File: $hostsPath"
        return
    }
    Add-Content -Path $hostsPath -Value "`n127.0.0.1  $HostName"
    Write-Host "Added 127.0.0.1  $HostName to hosts file" -ForegroundColor Green
}

function Start-DockerDesktop {
    $paths = @(
        "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe",
        "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
            Start-Process $p -ErrorAction SilentlyContinue
            return $true
        }
    }
    return $false
}

Write-Host @"

  ForgeRock AM + IDM — from scratch
  =================================
  Repo:  $RepoPath
  AM:    https://$Fqdn/am
  IDM:   https://$Fqdn/admin

"@ -ForegroundColor Cyan

if (-not $DeployOnly) {

    Write-Step "0" "Check virtualization"
    Write-Host "If WSL/Docker fail later, enable Intel VT-x / AMD-V in BIOS and reboot."

    Write-Step "1" "Git"
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Installing Git via winget..."
            winget install Git.Git --accept-package-agreements --accept-source-agreements
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("Path", "User")
        } else {
            Write-Host "Install Git: https://git-scm.com/download/win" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "Git OK: $(git --version)" -ForegroundColor Green

    if (-not $SkipPrereqs) {
        Write-Step "2" "WSL2 + Ubuntu"
        $wslList = wsl -l -v 2>$null
        if ($LASTEXITCODE -ne 0 -or $wslList -notmatch $WslDistro) {
            if (-not (Test-Admin)) {
                Write-Host "WSL not found. Re-run this script as Administrator:" -ForegroundColor Red
                Write-Host "  wsl --install -d Ubuntu-24.04"
                Write-Host "Then reboot, open Ubuntu once to create your user, and re-run."
                exit 1
            }
            Write-Host "Installing WSL + Ubuntu-24.04 (may require reboot)..."
            wsl --install -d Ubuntu-24.04 --no-launch
            Write-Host ""
            Write-Host "REBOOT Windows, open Ubuntu from Start menu, create username/password," -ForegroundColor Yellow
            Write-Host "install Docker Desktop, then re-run:" -ForegroundColor Yellow
            Write-Host "  cd $RepoPath"
            Write-Host "  .\forgeops\scripts\setup-from-scratch.ps1 -DeployOnly"
            exit 0
        }
        Write-Host "WSL OK:" -ForegroundColor Green
        wsl -l -v

        Write-Step "3" "Docker Desktop"
        $dockerExe = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
        if (-not (Test-Path $dockerExe)) {
            Write-Host "Docker Desktop not installed." -ForegroundColor Yellow
            Write-Host "  1. Download: https://www.docker.com/products/docker-desktop/"
            Write-Host "  2. Install with WSL2 backend"
            Write-Host "  3. Settings -> Resources -> Memory: 10 GB+"
            Write-Host "  4. Settings -> WSL Integration -> enable $WslDistro"
            Write-Host "  5. Re-run: .\forgeops\scripts\setup-from-scratch.ps1 -DeployOnly"
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                $r = Read-Host "Install Docker Desktop via winget now? (y/N)"
                if ($r -eq "y") {
                    winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
                    Write-Host "Finish Docker Desktop setup, then re-run with -DeployOnly"
                    exit 0
                }
            }
            exit 1
        }

        try {
            docker info 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "not running" }
            Write-Host "Docker OK" -ForegroundColor Green
        } catch {
            Start-DockerDesktop | Out-Null
            Write-Host "Waiting for Docker Desktop (30s)..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
            docker info 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Start Docker Desktop manually, wait for whale icon, then re-run -DeployOnly" -ForegroundColor Red
                exit 1
            }
        }
    }

    if (-not $SkipClone) {
        Write-Step "4" "Clone lab repo"
        if (-not (Test-Path "$RepoPath\.git")) {
            New-Item -ItemType Directory -Force -Path (Split-Path $RepoPath -Parent) | Out-Null
            git clone $RepoUrl $RepoPath
        }
        Set-Location $RepoPath
        git fetch origin
        git checkout $Branch
        git pull origin $Branch 2>$null
        Write-Host "Repo at $RepoPath on branch $Branch" -ForegroundColor Green
    } else {
        Set-Location $RepoPath
    }

    Write-Step "5" "Local config"
    & "$RepoPath\forgeops\scripts\init-local-windows.ps1"
    Ensure-HostsEntry
}

if (-not (Test-Path "$RepoPath\forgeops\scripts\setup-forgerock-wsl.ps1")) {
    Write-Host "Repo not found at $RepoPath. Run without -DeployOnly first." -ForegroundColor Red
    exit 1
}

Write-Step "6" "Deploy Ping AM + IDM (45-60 min)"
Write-Host "This runs inside WSL Ubuntu — not in PowerShell." -ForegroundColor Yellow
Write-Host ""
Write-Host "When prompted, open a SECOND Ubuntu window and run:" -ForegroundColor Yellow
Write-Host "  sudo minikube tunnel" -ForegroundColor White
Write-Host ""

Set-Location $RepoPath
& "$RepoPath\forgeops\scripts\setup-forgerock-wsl.ps1" -WslDistro $WslDistro -RepoPath $RepoPath

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== DONE ===" -ForegroundColor Green
    Write-Host "Platform:  https://$Fqdn/platform"
    Write-Host "AM:        https://$Fqdn/am"
    Write-Host "IDM:       https://$Fqdn/admin"
    Write-Host "Password:  see $RepoPath\forgeops\CREDENTIALS.local"
    Write-Host ""
    Write-Host "Next: labs/week-02-saml-sso/README.md"
}

exit $LASTEXITCODE
