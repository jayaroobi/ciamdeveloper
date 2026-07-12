# Windows — launch ForgeRock (original ForgeOps minikube plan)
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

Write-Host "=== ForgeRock on Windows - original ForgeOps plan ===" -ForegroundColor Cyan
Write-Host ""

# 1. Multipass installed?
if (-not (Get-Command multipass -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Multipass..." -ForegroundColor Yellow
    winget install Canonical.Multipass --accept-package-agreements --accept-source-agreements
    Write-Host "Restart PowerShell as Administrator, then re-run this script." -ForegroundColor Yellow
    exit 0
}

# 2. Ensure VM exists and is running
function Get-VMState {
    param([string]$Name)
    try {
        $json = multipass list --format json 2>$null | ConvertFrom-Json
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
    multipass start $VM_NAME
} else {
    Write-Host ("Creating VM {0} ({1} CPUs, {2} RAM)..." -f $VM_NAME, $VM_CPUS, $VM_MEM) -ForegroundColor Yellow

    $driver = ""
    try { $driver = (multipass get local.driver 2>$null).Trim() } catch {}
    if ($driver -eq "virtualbox") {
        Write-Host "Driver=virtualbox — use normal (non-Admin) PowerShell." -ForegroundColor DarkYellow
    } else {
        Write-Host "Tip: Hyper-V driver needs Administrator PowerShell." -ForegroundColor DarkYellow
    }

    $launchOut = multipass launch --name $VM_NAME --cpus $VM_CPUS --memory $VM_MEM --disk $VM_DISK 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host $launchOut -ForegroundColor Red
        Write-Host ""
        Write-Host "=== VM LAUNCH FAILED ===" -ForegroundColor Red
        Write-Host ""
        Write-Host "Common cause: 'Could not generate a new UUID' = Multipass cannot find its hypervisor."
        Write-Host ""
        Write-Host "Run diagnostics first:" -ForegroundColor Yellow
        Write-Host "  .\forgeops\scripts\diagnose-multipass-windows.ps1"
        Write-Host ""
        Write-Host "Quick fixes:" -ForegroundColor Yellow
        Write-Host "  A) Hyper-V (Windows Pro/Enterprise):"
        Write-Host "     - Admin PowerShell: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All"
        Write-Host "     - multipass set local.driver=hyperv"
        Write-Host "  B) VirtualBox (Windows Home or if Hyper-V fails):"
        Write-Host "     - Install VirtualBox, add C:\Program Files\Oracle\VirtualBox to SYSTEM PATH"
        Write-Host "     - Reboot, then NORMAL (non-Admin) PowerShell:"
        Write-Host "     - multipass set local.driver=virtualbox"
        Write-Host "  C) Clean retry: multipass delete --purge $VM_NAME"
        Write-Host "  D) Reboot Windows after any driver/PATH change"
        Write-Host ""
        Write-Host "If you saw 'Mounts are disabled' — update repo (mount no longer used):" -ForegroundColor Yellow
        Write-Host "  git pull origin $GIT_BRANCH"
        Write-Host ""
        Write-Host "Manual deploy after VM launch works:" -ForegroundColor Yellow
        Write-Host "  multipass shell $VM_NAME"
        Write-Host "  git clone $REPO_URL $VM_REPO && cd $VM_REPO && git checkout $GIT_BRANCH"
        Write-Host "  chmod +x forgeops/scripts/*.sh && ./forgeops/scripts/setup-forgerock.sh"
        exit 1
    }
}

# Verify VM is running before exec
$state = Get-VMState -Name $VM_NAME
if ($state -ne "Running") {
    Write-Host "VM $VM_NAME is not running (state: $state). Fix launch errors above." -ForegroundColor Red
    exit 1
}

# 3. Deploy via git INSIDE VM (no mount — Windows mounts disabled by default)
Write-Host ""
Write-Host "Deploying via git inside VM (mount not required)..." -ForegroundColor Cyan

$SetupCmd = @"
set -e
if [ -d '$VM_REPO/.git' ]; then
  cd '$VM_REPO' && git fetch origin && git checkout '$GIT_BRANCH' && git pull origin '$GIT_BRANCH'
else
  git clone '$REPO_URL' '$VM_REPO'
  cd '$VM_REPO' && git checkout '$GIT_BRANCH'
fi
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/setup-forgerock.sh
"@

Write-Host ""
Write-Host "Starting ForgeRock deploy (45-60 min)..." -ForegroundColor Cyan
Write-Host "When prompted, open a SECOND PowerShell window:" -ForegroundColor Yellow
Write-Host "  multipass shell $VM_NAME" -ForegroundColor White
Write-Host "  sudo minikube tunnel" -ForegroundColor White
Write-Host ""

multipass exec $VM_NAME -- bash -lc $SetupCmd

# 4. Windows hosts
$ip = "<VM-IP>"
try {
    $infoJson = multipass info $VM_NAME --format json | ConvertFrom-Json
    $prop = $infoJson.info.$VM_NAME
    if ($prop.ipv4.Count -gt 0) { $ip = $prop.ipv4[0] }
} catch {}

Write-Host ""
Write-Host "=== Add to C:\Windows\System32\drivers\etc\hosts (Admin Notepad) ===" -ForegroundColor Cyan
Write-Host "$ip  forgeops.example.com"
Write-Host ""
Write-Host "Open: https://forgeops.example.com/platform" -ForegroundColor Green
Write-Host "Credentials in VM: $VM_REPO/forgeops/CREDENTIALS.local" -ForegroundColor Green
