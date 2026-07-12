# Windows — launch ForgeRock (original ForgeOps minikube plan)
# Run in PowerShell as Administrator (recommended for Multipass/Hyper-V)
#
# Usage:
#   cd C:\ciam
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   .\forgeops\scripts\windows-forgerock.ps1

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
    Write-Host "Tip: Run PowerShell as Administrator if launch fails." -ForegroundColor DarkYellow
    $launchOut = multipass launch --name $VM_NAME --cpus $VM_CPUS --memory $VM_MEM --disk $VM_DISK 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host $launchOut -ForegroundColor Red
        Write-Host ""
        Write-Host "=== VM LAUNCH FAILED - try these fixes ===" -ForegroundColor Red
        Write-Host "1. Close PowerShell, open NEW PowerShell as Administrator"
        Write-Host "2. Enable virtualization in BIOS (Intel VT-x / AMD-V)"
        Write-Host "3. Windows Features: enable Hyper-V OR Virtual Machine Platform"
        Write-Host "4. Check driver: multipass get local.driver"
        Write-Host "   Try: multipass set local.driver=hyperv"
        Write-Host "   Or:  multipass set local.driver=virtualbox  (VirtualBox must be in PATH)"
        Write-Host "5. Clean retry: multipass delete --purge $VM_NAME"
        Write-Host "6. Reboot Windows, then re-run this script"
        Write-Host ""
        Write-Host "Manual deploy inside VM after launch works:" -ForegroundColor Yellow
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
