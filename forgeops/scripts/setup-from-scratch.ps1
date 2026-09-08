# Single setup file: precheck, recommend installs, then Ping AM + IDM deploy.
#
#   cd C:\ciam
#   .\forgeops\scripts\setup-from-scratch.ps1
#
# Options:
#   -PrecheckOnly   show OK/MISSING/WARN and recommended installs, then exit
#   -DeployOnly     skip Git/WSL/Docker install; run ForgeOps deploy
#   -SkipPrecheck   skip the report (not recommended)

param(
    [string]$RepoPath = "C:\ciam",
    [string]$Branch = "cursor/forgeops-ciam-career-lab-fe67",
    [string]$WslDistro = "Ubuntu",
    [switch]$SkipPrereqs,
    [switch]$SkipClone,
    [switch]$SkipPrecheck,
    [switch]$PrecheckOnly,
    [switch]$DeployOnly
)

$ErrorActionPreference = "Continue"
$RepoUrl = "https://github.com/jayaroobi/ciamdeveloper.git"
$Fqdn = "forgeops.example.com"

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = [Security.Principal.WindowsPrincipal]$id
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Step {
    param([string]$Num, [string]$Msg)
    Write-Host ""
    Write-Host ("=== Step {0} - {1} ===" -f $Num, $Msg) -ForegroundColor Cyan
}

function Write-Check {
    param([string]$Status, [string]$Name, [string]$Detail)
    $color = "White"
    if ($Status -eq "OK") { $color = "Green" }
    elseif ($Status -eq "MISSING") { $color = "Red" }
    elseif ($Status -eq "WARN") { $color = "Yellow" }
    elseif ($Status -eq "INFO") { $color = "Gray" }
    Write-Host ("[{0,-7}] {1,-28} {2}" -f $Status, $Name, $Detail) -ForegroundColor $color
}

function Get-WslText {
    $script:WslExit = 1
    $outFile = Join-Path $env:TEMP "ciam-wsl-list.txt"
    $errFile = Join-Path $env:TEMP "ciam-wsl-list.err"
    Remove-Item $outFile, $errFile -ErrorAction SilentlyContinue
    $wslExe = Join-Path $env:SystemRoot "System32\wsl.exe"
    if (-not (Test-Path $wslExe)) {
        return "not installed"
    }
    try {
        $p = Start-Process -FilePath $wslExe -ArgumentList @("-l","-v") `
            -NoNewWindow -PassThru `
            -RedirectStandardOutput $outFile `
            -RedirectStandardError $errFile `
            -ErrorAction SilentlyContinue
        if (-not $p) { return "not installed" }
        if (-not $p.WaitForExit(12000)) {
            try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
            $script:WslExit = 1
            return "not installed"
        }
        $script:WslExit = $p.ExitCode
    } catch {
        $script:WslExit = 1
        return "not installed"
    }
    $text = ""
    foreach ($f in @($outFile, $errFile)) {
        if (Test-Path $f) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($f)
                if ($bytes.Length -ge 2 -and $bytes[1] -eq 0) {
                    $text += [System.Text.Encoding]::Unicode.GetString($bytes)
                } else {
                    $text += [System.IO.File]::ReadAllText($f)
                }
            } catch {}
        }
    }
    if (-not $text) { $text = "not installed" }
    return ($text -replace "`0", "")
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

function Get-DockerExe {
    $p1 = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
    $p2 = "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $p1) { return $p1 }
    if (Test-Path $p2) { return $p2 }
    return $null
}

# ---------- PRECHECK ----------
$script:Ok = @()
$script:Missing = @()
$script:Warn = @()
$script:Recommend = @()

function Invoke-Precheck {
    Write-Host ""
    Write-Host "PHASE 1 - Precheck (nothing is installed yet)" -ForegroundColor Cyan
    Write-Host ""

    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $ramGb = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    $freeGb = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
    $cpuCount = (Get-CimInstance Win32_Processor | Measure-Object NumberOfLogicalProcessors -Sum).Sum

    Write-Check "INFO" "Computer" $env:COMPUTERNAME
    Write-Check "INFO" "Windows" ("{0} ({1})" -f $os.Caption.Trim(), $os.Version)
    Write-Check "INFO" "PowerShell" $PSVersionTable.PSVersion.ToString()
    Write-Check "INFO" "Administrator" ($(if (Test-Admin) { "Yes" } else { "No - use Admin for WSL install" }))

    if ($ramGb -ge 16) {
        Write-Check "OK" "RAM" ("{0} GB (need 16 GB+)" -f $ramGb)
        $script:Ok += "RAM"
    } elseif ($ramGb -ge 12) {
        Write-Check "WARN" "RAM" ("{0} GB (tight; minikube needs ~9 GB)" -f $ramGb)
        $script:Warn += "Close extra apps. Docker memory 8-10 GB."
    } else {
        Write-Check "MISSING" "RAM" ("{0} GB (need 16 GB for AM+IDM)" -f $ramGb)
        $script:Missing += "RAM"
        $script:Recommend += "This laptop may not run full ForgeOps. Need 16 GB RAM."
    }

    if ($cpuCount -ge 4) {
        Write-Check "OK" "CPU cores" "$cpuCount (need 4+)"
        $script:Ok += "CPU"
    } else {
        Write-Check "WARN" "CPU cores" "$cpuCount (4+ recommended)"
    }

    if ($freeGb -ge 50) {
        Write-Check "OK" "Disk C: free" ("{0} GB" -f $freeGb)
        $script:Ok += "Disk"
    } elseif ($freeGb -ge 40) {
        Write-Check "WARN" "Disk C: free" ("{0} GB (40 GB min)" -f $freeGb)
    } else {
        Write-Check "MISSING" "Disk C: free" ("{0} GB (need 40 GB+)" -f $freeGb)
        $script:Missing += "Disk"
        $script:Recommend += "Free disk space on C: (at least 40 GB)."
    }

    try { $virt = (Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled } catch { $virt = $null }
    if ($virt -eq $true) {
        Write-Check "OK" "BIOS virtualization" "Enabled"
        $script:Ok += "VTx"
    } elseif ($virt -eq $false) {
        Write-Check "MISSING" "BIOS virtualization" "Disabled"
        $script:Missing += "BIOS virtualization"
        $script:Recommend += "Reboot into BIOS and enable Intel VT-x or AMD-V."
    } else {
        Write-Check "INFO" "BIOS virtualization" "Could not read"
    }

    $vmpOn = $false
    try {
        $vmp = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
        $vmpOn = $vmp -and ($vmp.State -eq "Enabled")
    } catch {}
    if ($vmpOn) {
        Write-Check "OK" "Virtual Machine Platform" "Enabled"
        $script:Ok += "VMP"
    } else {
        Write-Check "MISSING" "Virtual Machine Platform" "Disabled (needed for WSL2)"
        $script:Missing += "Virtual Machine Platform"
        $script:Recommend += "Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All"
        $script:Recommend += "Then reboot."
    }

    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Check "OK" "Git" (git --version)
        $script:Ok += "Git"
    } else {
        Write-Check "MISSING" "Git" "Not in PATH"
        $script:Missing += "Git"
        $script:Recommend += "winget install Git.Git --accept-package-agreements --accept-source-agreements"
    }

    if (Test-Path "$RepoPath\README.md") {
        Write-Check "OK" "Lab repo" $RepoPath
        $script:Ok += "Repo"
    } else {
        Write-Check "MISSING" "Lab repo" ("Not found at {0}" -f $RepoPath)
        $script:Missing += "Repo"
        $script:Recommend += "cd C:\; git clone https://github.com/jayaroobi/ciamdeveloper.git ciam"
    }

    $ep = Get-ExecutionPolicy -Scope CurrentUser
    if ($ep -in @("RemoteSigned", "Unrestricted", "Bypass")) {
        Write-Check "OK" "ExecutionPolicy" $ep
    } else {
        Write-Check "WARN" "ExecutionPolicy" "$ep"
        $script:Recommend += "Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
    }

    $wslText = Get-WslText
    if ($wslText -match "not installed" -or ($script:WslExit -ne 0 -and $wslText -notmatch "Ubuntu")) {
        Write-Check "MISSING" "WSL" "Not installed"
        $script:Missing += "WSL"
        $script:Recommend += "wsl --install -d Ubuntu"
        $script:Recommend += "REBOOT, open Ubuntu, create username/password"
    } else {
        Write-Check "OK" "WSL" "Installed"
        $script:Ok += "WSL"
        if ($wslText -match "Ubuntu") {
            Write-Check "OK" "Ubuntu distro" "Found"
            $script:Ok += "Ubuntu"
        } else {
            Write-Check "MISSING" "Ubuntu distro" "Install Ubuntu"
            $script:Missing += "Ubuntu"
            $script:Recommend += "wsl --install -d Ubuntu"
            $script:Recommend += "REBOOT, open Ubuntu, create username/password"
        }
    }

    $dockerExe = Get-DockerExe
    if ($dockerExe) {
        Write-Check "OK" "Docker Desktop app" $dockerExe
        $script:Ok += "DockerDesktop"
    } else {
        Write-Check "MISSING" "Docker Desktop app" "Not installed"
        $script:Missing += "Docker Desktop"
        $script:Recommend += "winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements"
        $script:Recommend += "Or: https://www.docker.com/products/docker-desktop/"
        $script:Recommend += "Settings -> Resources -> Memory 10 GB; WSL Integration -> Ubuntu ON"
    }

    $dockerRunning = $false
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $dockerRunning = $true
            Write-Check "OK" "Docker engine" "Running"
            $script:Ok += "DockerEngine"
        } else {
            Write-Check "WARN" "Docker engine" "Not running - start Docker Desktop"
            $script:Warn += "Start Docker Desktop (whale icon must be steady)."
            $script:Recommend += "Start Docker Desktop and wait until it is ready."
        }
    } elseif ($dockerExe) {
        Write-Check "WARN" "Docker CLI" "Restart PowerShell after Docker install"
        $script:Recommend += "Close PowerShell, open a new Admin window."
    } else {
        Write-Check "MISSING" "Docker engine" "Not available"
    }

    if (($script:Ok -contains "Ubuntu") -and $dockerRunning) {
        $dCheck = wsl -d $WslDistro -- bash -lc "docker info >/dev/null 2>&1 && echo OK || echo FAIL" 2>$null
        if ($dCheck -match "OK") {
            Write-Check "OK" "Docker in WSL" "Works in Ubuntu"
            $script:Ok += "DockerWSL"
        } else {
            Write-Check "WARN" "Docker in WSL" "Enable WSL integration"
            $script:Recommend += "Docker Desktop -> Settings -> Resources -> WSL Integration -> Ubuntu ON"
        }
    }

    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $hostsContent = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
    if ($hostsContent -match [regex]::Escape($Fqdn)) {
        Write-Check "OK" "Hosts file" $Fqdn
    } else {
        Write-Check "WARN" "Hosts file" ("Add 127.0.0.1  {0} (script can add later)" -f $Fqdn)
        $script:Recommend += "Admin Notepad hosts file: 127.0.0.1  forgeops.example.com"
    }

    Write-Host ""
    Write-Host "Summary" -ForegroundColor Cyan
    Write-Host ("  OK:      {0}" -f $(if ($script:Ok.Count) { $script:Ok -join ", " } else { "(none)" })) -ForegroundColor Green
    Write-Host ("  WARN:    {0}" -f $script:Warn.Count) -ForegroundColor Yellow
    Write-Host ("  MISSING: {0}" -f $(if ($script:Missing.Count) { $script:Missing -join ", " } else { "(none)" })) -ForegroundColor $(if ($script:Missing.Count) { "Red" } else { "Green" })

    Write-Host ""
    Write-Host "Recommended installs / actions" -ForegroundColor Cyan
    if ($script:Recommend.Count -eq 0 -and $script:Missing.Count -eq 0) {
        Write-Host "  All required items look ready for AM + IDM deploy." -ForegroundColor Green
    } else {
        $i = 1
        foreach ($cmd in $script:Recommend) {
            Write-Host ("  {0}. {1}" -f $i, $cmd)
            $i++
        }
    }
    Write-Host ""
}

Write-Host ""
Write-Host "  ForgeRock AM + IDM - single setup (v2)" -ForegroundColor Cyan
Write-Host "  =================================" -ForegroundColor Cyan
Write-Host ("  Repo:  {0}" -f $RepoPath)
Write-Host ("  AM:    https://{0}/am" -f $Fqdn)
Write-Host ("  IDM:   https://{0}/admin" -f $Fqdn)

if (-not $SkipPrecheck) {
    Invoke-Precheck
    if ($PrecheckOnly) {
        Write-Host "Precheck only. When ready, run:" -ForegroundColor Yellow
        Write-Host "  .\forgeops\scripts\setup-from-scratch.ps1"
        if ($script:Missing.Count -gt 0) { exit 1 }
        exit 0
    }
    $blockers = $script:Missing | Where-Object { $_ -in @("RAM", "Disk", "BIOS virtualization") }
    if ($blockers.Count -gt 0) {
        Write-Host "Hardware blockers must be fixed before AM/IDM install." -ForegroundColor Red
        exit 1
    }
    Write-Host "Next: install missing software (Git/WSL/Docker), then deploy AM+IDM." -ForegroundColor Yellow
    $go = Read-Host "Continue with recommended installs and deploy? (Y/n)"
    if ($go -eq "n" -or $go -eq "N") {
        Write-Host "Stopped. Re-run this same script when ready."
        exit 0
    }
}

# ---------- INSTALL + DEPLOY ----------
if (-not $DeployOnly) {

    Write-Step -Num "1" -Msg "Git"
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
    Write-Host ("Git OK: {0}" -f (git --version)) -ForegroundColor Green

    if (-not $SkipPrereqs) {
        Write-Step -Num "2" -Msg "WSL2 + Ubuntu"
        $wslText = Get-WslText
        $wslMissing = ($wslText -match "not installed") -or ($script:WslExit -ne 0) -or ($wslText -notmatch $WslDistro)
        if ($wslMissing) {
            if (-not (Test-Admin)) {
                Write-Host "WSL is not installed. Re-run as Administrator, or run:" -ForegroundColor Red
                Write-Host "  wsl --install -d Ubuntu"
                Write-Host "Then reboot, open Ubuntu, create user, install Docker Desktop, re-run this script."
                exit 1
            }
            Write-Host "Installing WSL + Ubuntu (requires reboot)..." -ForegroundColor Yellow
            wsl --install -d Ubuntu
            Write-Host ""
            Write-Host "REBOOT Windows now." -ForegroundColor Yellow
            Write-Host "After reboot:"
            Write-Host "  1. Open Ubuntu from Start, create username and password"
            Write-Host "  2. Install Docker Desktop (10 GB memory, WSL integration ON)"
            Write-Host "  3. cd C:\ciam"
            Write-Host "     .\forgeops\scripts\setup-from-scratch.ps1 -DeployOnly"
            exit 0
        }
        Write-Host "WSL OK" -ForegroundColor Green

        Write-Step -Num "3" -Msg "Docker Desktop"
        $dockerExe = Get-DockerExe
        if (-not $dockerExe) {
            Write-Host "Docker Desktop not installed." -ForegroundColor Yellow
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                $r = Read-Host "Install Docker Desktop via winget now? (Y/n)"
                if ($r -ne "n" -and $r -ne "N") {
                    winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
                    Write-Host "Finish Docker Desktop first-run, set memory 10 GB, enable Ubuntu WSL integration."
                    Write-Host "Then re-run: .\forgeops\scripts\setup-from-scratch.ps1 -DeployOnly"
                    exit 0
                }
            }
            Write-Host "Install: https://www.docker.com/products/docker-desktop/"
            exit 1
        }

        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Start-DockerDesktop | Out-Null
            Write-Host "Waiting for Docker Desktop (30s)..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
            docker info 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Start Docker Desktop, wait for whale icon, then re-run -DeployOnly" -ForegroundColor Red
                exit 1
            }
        }
        Write-Host "Docker OK" -ForegroundColor Green
    }

    if (-not $SkipClone) {
        Write-Step -Num "4" -Msg "Clone / update lab repo"
        if (-not (Test-Path "$RepoPath\.git")) {
            New-Item -ItemType Directory -Force -Path (Split-Path $RepoPath -Parent) | Out-Null
            git clone $RepoUrl $RepoPath
        }
        Set-Location $RepoPath
        git fetch origin
        git checkout $Branch
        git pull origin $Branch 2>$null
        Write-Host ("Repo at {0} on branch {1}" -f $RepoPath, $Branch) -ForegroundColor Green
    } else {
        Set-Location $RepoPath
    }

    Write-Step -Num "5" -Msg "Local config + hosts"
    & "$RepoPath\forgeops\scripts\init-local-windows.ps1"
    Ensure-HostsEntry
}

if (-not (Test-Path "$RepoPath\forgeops\scripts\setup-forgerock-wsl.ps1")) {
    Write-Host "Repo not found at $RepoPath." -ForegroundColor Red
    exit 1
}

Write-Step -Num "6" -Msg "Deploy Ping AM + IDM (45-60 min)"
Write-Host "This runs inside WSL Ubuntu, not in PowerShell." -ForegroundColor Yellow
Write-Host ""
Write-Host "When prompted, open a SECOND Ubuntu window and run:" -ForegroundColor Yellow
Write-Host "  sudo minikube tunnel" -ForegroundColor White
Write-Host ""

Set-Location $RepoPath
$deployExit = 1
try {
    & "$RepoPath\forgeops\scripts\setup-forgerock-wsl.ps1" -WslDistro $WslDistro -RepoPath $RepoPath
    if (-not $?) {
        $deployExit = 1
    } elseif ($null -eq $LASTEXITCODE) {
        $deployExit = 0
    } else {
        $deployExit = $LASTEXITCODE
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    $deployExit = 1
}

if ($deployExit -eq 0) {
    Write-Host ""
    Write-Host "=== DONE ===" -ForegroundColor Green
    Write-Host ("Platform:  https://{0}/platform" -f $Fqdn)
    Write-Host ("AM:        https://{0}/am" -f $Fqdn)
    Write-Host ("IDM:       https://{0}/admin" -f $Fqdn)
    Write-Host ("Password:  see {0}\forgeops\CREDENTIALS.local" -f $RepoPath)
    exit 0
}

Write-Host ""
Write-Host "=== DEPLOY DID NOT FINISH ===" -ForegroundColor Red
Write-Host "Ignore Platform/AM/IDM URLs until this step succeeds."
Write-Host "Re-run: .\forgeops\scripts\setup-from-scratch.ps1 -DeployOnly"
Write-Host "Or from Ubuntu (not PowerShell):"
Write-Host "  wsl -d Ubuntu"
Write-Host "  cd /mnt/c/ciam"
Write-Host "  ./forgeops/scripts/setup-forgerock.sh"
exit $deployExit
