# Windows — launch ForgeRock (original ForgeOps minikube plan)
# Run in PowerShell AS YOUR WINDOWS USER (not Cursor workspace terminal)
#
# Prerequisites: winget, virtualization enabled in BIOS
#
# Usage:
#   cd C:\path\to\ciamdeveloper
#   .\forgeops\scripts\windows-forgerock.ps1

$ErrorActionPreference = "Stop"
$VM_NAME = "forgeops-lab"
$VM_CPUS = 4
$VM_MEM = "9G"
$VM_DISK = "40G"

Write-Host "=== ForgeRock on Windows — original ForgeOps plan ===" -ForegroundColor Cyan
Write-Host ""

# 1. Multipass
if (-not (Get-Command multipass -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Multipass..." -ForegroundColor Yellow
    winget install Canonical.Multipass --accept-package-agreements --accept-source-agreements
    Write-Host "Restart PowerShell after install, then re-run this script." -ForegroundColor Yellow
    exit 0
}

# 2. VM
$existing = multipass list --format json 2>$null | ConvertFrom-Json
$vm = $existing.list | Where-Object { $_.name -eq $VM_NAME -and $_.state -eq "Running" }
if (-not $vm) {
    Write-Host "Creating VM $VM_NAME ($VM_CPUS CPU, $VM_MEM RAM)..." -ForegroundColor Yellow
    multipass launch --name $VM_NAME --cpus $VM_CPUS --memory $VM_MEM --disk $VM_DISK
} else {
    Write-Host "VM $VM_NAME already running." -ForegroundColor Green
}

# 3. Mount repo if we're in ciamdeveloper
$RepoPath = (Get-Location).Path
if (Test-Path "$RepoPath\forgeops\scripts\setup-forgerock.sh") {
    Write-Host "Mounting repo into VM..." -ForegroundColor Yellow
    multipass mount "$RepoPath" "${VM_NAME}:/home/ubuntu/ciamdeveloper" 2>$null
    $SetupCmd = "cd /home/ubuntu/ciamdeveloper && chmod +x forgeops/scripts/*.sh && ./forgeops/scripts/setup-forgerock.sh"
} else {
    Write-Host "Repo not found locally — cloning inside VM..." -ForegroundColor Yellow
    $SetupCmd = @"
git clone https://github.com/jayaroobi/ciamdeveloper.git /home/ubuntu/ciamdeveloper &&
cd /home/ubuntu/ciamdeveloper &&
git checkout cursor/forgeops-ciam-career-lab-fe67 &&
chmod +x forgeops/scripts/*.sh &&
./forgeops/scripts/setup-forgerock.sh
"@
}

Write-Host ""
Write-Host "Starting ForgeRock deploy inside VM (45-60 min)..." -ForegroundColor Cyan
Write-Host "You will need a SECOND Multipass shell for: sudo minikube tunnel" -ForegroundColor Yellow
Write-Host ""
Write-Host "  multipass shell $VM_NAME" -ForegroundColor White
Write-Host "  sudo minikube tunnel" -ForegroundColor White
Write-Host ""

multipass exec $VM_NAME -- bash -lc "$SetupCmd"

# 4. Windows hosts
$ip = (multipass info $VM_NAME --format json | ConvertFrom-Json).info.$VM_NAME.ipv4[0]
Write-Host ""
Write-Host "=== Add to C:\Windows\System32\drivers\etc\hosts (Admin Notepad) ===" -ForegroundColor Cyan
Write-Host "$ip  forgeops.example.com"
Write-Host ""
Write-Host "Then open: https://forgeops.example.com/platform" -ForegroundColor Green
Write-Host "Credentials inside VM: ~/ciamdeveloper/forgeops/CREDENTIALS.local" -ForegroundColor Green
