# Pre-flight checks for Multipass on Windows
# Run BEFORE windows-forgerock.ps1 when launch fails
#
# Usage:
#   cd C:\ciam
#   .\forgeops\scripts\diagnose-multipass-windows.ps1

$ErrorActionPreference = "Continue"

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = [Security.Principal.WindowsPrincipal]$id
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-VBoxManage {
    $candidates = @(
        "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe",
        "${env:ProgramFiles(x86)}\Oracle\VirtualBox\VBoxManage.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    $cmd = Get-Command VBoxManage -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

Write-Host "=== Multipass pre-flight (Windows) ===" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()

# 1. Multipass installed
if (-not (Get-Command multipass -ErrorAction SilentlyContinue)) {
    Write-Host "[FAIL] multipass not found in PATH" -ForegroundColor Red
    Write-Host "       Install: winget install Canonical.Multipass"
    exit 1
}
Write-Host "[OK]   multipass found: $((Get-Command multipass).Source)" -ForegroundColor Green

# 2. Admin context
$isAdmin = Test-Admin
Write-Host ("[INFO] Running as Administrator: {0}" -f $isAdmin) -ForegroundColor Gray

# 3. Driver
$driver = "unknown"
try {
    $driver = (multipass get local.driver 2>$null).Trim()
} catch {}
Write-Host "[INFO] Multipass driver: $driver" -ForegroundColor Gray

# 4. Hyper-V / VM Platform
$hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
$vmp = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
$hypervOn = $hyperv -and ($hyperv.State -eq "Enabled")
$vmpOn = $vmp -and ($vmp.State -eq "Enabled")
Write-Host ("[INFO] Hyper-V: {0}  |  Virtual Machine Platform: {1}" -f $(if ($hypervOn) {"Enabled"} else {"Disabled"}), $(if ($vmpOn) {"Enabled"} else {"Disabled"})) -ForegroundColor Gray

# 5. VirtualBox
$vbox = Find-VBoxManage
if ($vbox) {
    Write-Host "[OK]   VBoxManage: $vbox" -ForegroundColor Green
} else {
    Write-Host "[WARN] VBoxManage not found (needed if driver=virtualbox)" -ForegroundColor Yellow
}

# 6. Driver-specific checks
switch -Regex ($driver) {
    "hyperv|qemu" {
        if (-not $isAdmin) {
            $warnings += "Hyper-V driver: run PowerShell as Administrator for launch."
        }
        if (-not $hypervOn -and -not $vmpOn) {
            $issues += "Enable Hyper-V or Virtual Machine Platform in Windows Optional Features, then reboot."
        }
    }
    "virtualbox" {
        if (-not $vbox) {
            $issues += "Driver is virtualbox but VBoxManage.exe not found. Install VirtualBox or add it to System PATH."
        } else {
            $vboxDir = Split-Path $vbox -Parent
            $sysPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            if ($sysPath -notlike "*$vboxDir*") {
                $issues += "Add to System PATH (not just User PATH), then reboot: $vboxDir"
            }
            if ($isAdmin) {
                $warnings += "VirtualBox driver: avoid Administrator PowerShell — use normal user shell for multipass launch."
            }
        }
        if ($hypervOn) {
            $warnings += "Hyper-V and VirtualBox conflict. Use ONE driver: multipass set local.driver=hyperv OR install VirtualBox and disable Hyper-V."
        }
    }
    default {
        if ($hypervOn -or $vmpOn) {
            Write-Host "[TIP]  Try: multipass set local.driver=hyperv" -ForegroundColor Yellow
        } elseif ($vbox) {
            Write-Host "[TIP]  Try: multipass set local.driver=virtualbox" -ForegroundColor Yellow
        } else {
            $issues += "No hypervisor detected. Enable Hyper-V/VM Platform OR install VirtualBox, then set local.driver."
        }
    }
}

# 7. Multipass service
try {
    $svc = Get-Service -Name "Multipass" -ErrorAction SilentlyContinue
    if ($svc) {
        $color = if ($svc.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host ("[INFO] Multipass service: {0}" -f $svc.Status) -ForegroundColor $color
        if ($svc.Status -ne "Running") {
            $issues += "Start Multipass service: Restart-Service Multipass (as Administrator)"
        }
    }
} catch {}

# 8. Stale VM
try {
    $json = multipass list --format json 2>$null | ConvertFrom-Json
    foreach ($item in $json.list) {
        if ($item.name -eq "forgeops-lab" -and $item.state -ne "Running") {
            $warnings += "Stale VM 'forgeops-lab' in state '$($item.state)'. Try: multipass delete --purge forgeops-lab"
        }
    }
} catch {}

Write-Host ""
if ($issues.Count -gt 0) {
    Write-Host "=== FIX THESE FIRST ===" -ForegroundColor Red
    $i = 1
    foreach ($msg in $issues) {
        Write-Host ("  {0}. {1}" -f $i, $msg)
        $i++
    }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "=== WARNINGS ===" -ForegroundColor Yellow
    foreach ($msg in $warnings) {
        Write-Host "  - $msg"
    }
    Write-Host ""
}

if ($issues.Count -eq 0) {
    Write-Host "Pre-flight OK. Try:" -ForegroundColor Green
    Write-Host "  multipass launch --name forgeops-lab --cpus 4 --memory 9G --disk 40G"
    Write-Host "  .\forgeops\scripts\windows-forgerock.ps1"
} else {
    Write-Host "After fixes, reboot Windows, then re-run this script." -ForegroundColor Yellow
    exit 1
}
