# Windows — launch ForgeRock via Multipass (fallback; prefer WSL2)
#
# Usage:
#   cd C:\ciam
#   git pull origin cursor/forgeops-ciam-career-lab-fe67
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   .\forgeops\scripts\diagnose-multipass-windows.ps1   # if launch fails
#   .\forgeops\scripts\windows-forgerock.ps1
#
# Notes:
#   - Mounts are NOT used (disabled on Windows Multipass) — repo cloned via git inside VM
#   - Hyper-V driver: run PowerShell as Administrator
#   - VirtualBox driver: use NORMAL (non-Admin) PowerShell

$ErrorActionPreference = "Continue"
$VM_NAME = "forgeops-lab"
$VM_CPUS = 4
$VM_MEM = "9G"
$VM_DISK = "40G"
$GIT_BRANCH = "cursor/forgeops-ciam-career-lab-fe67"
$REPO_URL = "https://github.com/jayaroobi/ciamdeveloper.git"
$VM_REPO = "/home/ubuntu/ciam"
$MultipassExe = "C:\Program Files\Multipass\bin\multipass.exe"

Write-Host "=== ForgeRock on Windows - Multipass fallback ===" -ForegroundColor Cyan
Write-Host ""

# Resolve multipass binary (often missing from PATH)
if (Test-Path $MultipassExe) {
    Write-Host "Using Multipass: $MultipassExe" -ForegroundColor Green
} elseif (Get-Command multipass -ErrorAction SilentlyContinue) {
    $MultipassExe = (Get-Command multipass).Source
} else {
    Write-Host "Installing Multipass..." -ForegroundColor Yellow
    winget install Canonical.Multipass --accept-package-agreements --accept-source-agreements
    Write-Host "Restart PowerShell as Administrator, then re-run this script." -ForegroundColor Yellow
    exit 0
}

function Invoke-Multipass {
    param([Parameter(ValueFromRemainingArguments = $true)]$Args)
    & $MultipassExe @Args
}

function Get-VMState {
    param([string]$Name)
    try {
        $json = Invoke-Multipass list --format json 2>$null | ConvertFrom-Json
        foreach ($item in $json.list) {
            if ($item.name -eq $Name) { return $item.state }
        }
    } catch {}
    return $null
}

$state = Get-VMState -Name $VM_NAME

if ($state -eq "Running") {
    Write-Host "VM $VM_NAME is running." -ForegroundColor Green
} elseif ($state -eq "Stopped") {
    Write-Host "Starting existing VM $VM_NAME ..." -ForegroundColor Yellow
    Invoke-Multipass start $VM_NAME
} else {
    Write-Host ("Creating VM {0} ({1} CPUs, {2} RAM)..." -f $VM_NAME, $VM_CPUS, $VM_MEM) -ForegroundColor Yellow

    $driver = ""
    try { $driver = (Invoke-Multipass get local.driver 2>$null).Trim() } catch {}
    if ($driver -eq "virtualbox") {
        Write-Host "Driver=virtualbox — use normal (non-Admin) PowerShell." -ForegroundColor DarkYellow
    } else {
        Write-Host "Tip: Hyper-V driver needs Administrator PowerShell." -ForegroundColor DarkYellow
    }

    $launchOut = Invoke-Multipass launch --name $VM_NAME --cpus $VM_CPUS --memory $VM_MEM --disk $VM_DISK 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host $launchOut -ForegroundColor Red
        Write-Host ""
        Write-Host "=== VM LAUNCH FAILED ===" -ForegroundColor Red
        Write-Host "Run: .\forgeops\scripts\diagnose-multipass-windows.ps1" -ForegroundColor Yellow
        Write-Host "Or prefer WSL2: .\forgeops\scripts\setup-forgerock-wsl.ps1" -ForegroundColor Yellow
        exit 1
    }
}

$state = Get-VMState -Name $VM_NAME
if ($state -ne "Running") {
    Write-Host "VM $VM_NAME is not running (state: $state)." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Deploying via git inside VM (mount not required)..." -ForegroundColor Cyan

# Array join, not a here-string: Windows PowerShell 5.1 cannot parse @" "@
# when this file has Unix (LF) line endings.
$SetupCmd = @(
    'set -e'
    ('if [ -d ''{0}/.git'' ]; then' -f $VM_REPO)
    ('  cd ''{0}'' && git fetch origin && git checkout ''{1}'' && git pull origin ''{1}''' -f $VM_REPO, $GIT_BRANCH)
    'else'
    ('  git clone ''{0}'' ''{1}''' -f $REPO_URL, $VM_REPO)
    ('  cd ''{0}'' && git checkout ''{1}''' -f $VM_REPO, $GIT_BRANCH)
    'fi'
    'chmod +x forgeops/scripts/*.sh'
    './forgeops/scripts/setup-forgerock.sh'
) -join "`n"

Write-Host "Starting ForgeRock deploy (45-60 min)..." -ForegroundColor Cyan
Write-Host "When prompted, open a SECOND PowerShell window:" -ForegroundColor Yellow
Write-Host ('  & "{0}" shell {1}' -f $MultipassExe, $VM_NAME) -ForegroundColor White
Write-Host "  sudo minikube tunnel" -ForegroundColor White
Write-Host "Then return here and press Enter." -ForegroundColor Yellow
Write-Host ""

Invoke-Multipass exec $VM_NAME -- bash -lc $SetupCmd

$ip = "<VM-IP>"
try {
    $infoJson = Invoke-Multipass info $VM_NAME --format json | ConvertFrom-Json
    $prop = $infoJson.info.$VM_NAME
    if (-not $prop) {
        $prop = $infoJson.info.PSObject.Properties.Value | Select-Object -First 1
    }
    if ($prop.ipv4.Count -gt 0) { $ip = $prop.ipv4[0] }
} catch {}

Write-Host ""
Write-Host "=== Add to C:\Windows\System32\drivers\etc\hosts (Admin Notepad) ===" -ForegroundColor Cyan
Write-Host "$ip  forgeops.example.com"
Write-Host ""
Write-Host "Open: https://forgeops.example.com/platform" -ForegroundColor Green
Write-Host "Credentials in VM: $VM_REPO/forgeops/CREDENTIALS.local" -ForegroundColor Green
