# Your local setup (Windows)

**Repo path:** `C:\ciam`  
**Machine:** LAPTOP-4GLJMDEF

## One-time init (PowerShell)

```powershell
cd C:\ciam
git pull origin cursor/forgeops-ciam-career-lab-fe67
.\forgeops\scripts\init-local-windows.ps1
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Creates:
- `forgeops/config/env.local` — your local ForgeOps settings
- `forgeops/config/local-path.txt` — repo path reference (gitignored)

## Deploy ForgeRock

```powershell
cd C:\ciam
git pull origin cursor/forgeops-ciam-career-lab-fe67
.\forgeops\scripts\windows-forgerock.ps1
```

> Mounts are **not used** — repo is cloned via git inside the VM (Windows disables Multipass mounts by default).

### If you see two errors together

| Error | Meaning |
|-------|---------|
| `Mounts are disabled on this installation of Multipass` | Old script — run `git pull` (mount removed) |
| `Could not generate a new UUID: Process failed to start` | Multipass cannot find Hyper-V or VirtualBox |

### Fix UUID / launch failure

**Step 1 — pull latest + diagnose**

```powershell
cd C:\ciam
git pull origin cursor/forgeops-ciam-career-lab-fe67
.\forgeops\scripts\diagnose-multipass-windows.ps1
```

**Step 2 — pick ONE hypervisor**

**Option A — Hyper-V** (Windows Pro/Enterprise, Admin PowerShell):

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
multipass set local.driver=hyperv
multipass delete --purge forgeops-lab
# Reboot Windows
.\forgeops\scripts\windows-forgerock.ps1
```

**Option B — VirtualBox** (Windows Home, or if Hyper-V fails):

1. Install VirtualBox: https://www.virtualbox.org/
2. Add `C:\Program Files\Oracle\VirtualBox` to **System** PATH (not User PATH only)
3. Reboot Windows
4. Open **normal** (non-Admin) PowerShell:

```powershell
multipass set local.driver=virtualbox
multipass delete --purge forgeops-lab
.\forgeops\scripts\windows-forgerock.ps1
```

Enable virtualization in BIOS (Intel VT-x / AMD-V) if both options fail.

Second window when prompted:

```powershell
multipass shell forgeops-lab
sudo minikube tunnel
```

## Hosts file

Add to `C:\Windows\System32\drivers\etc\hosts` (Admin):

```text
<VM-IP>  forgeops.example.com
```

Get IP: `multipass info forgeops-lab`

## Open ForgeRock

https://forgeops.example.com/platform

Credentials: inside VM at `/home/ubuntu/ciam/forgeops/CREDENTIALS.local`
