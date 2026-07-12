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

**Run PowerShell as Administrator** (required for Multipass VM launch on many Windows PCs).

```powershell
cd C:\ciam
.\forgeops\scripts\windows-forgerock.ps1
```

> Mounts are **not used** — repo is cloned via git inside the VM (Windows disables Multipass mounts by default).

### If VM launch fails (UUID error)

```powershell
# Run as Administrator
multipass get local.driver
multipass set local.driver=hyperv
# or if using VirtualBox:
multipass set local.driver=virtualbox

multipass delete --purge forgeops-lab
# Reboot Windows, then re-run windows-forgerock.ps1
```

Enable in Windows: **Settings → System → Optional features → Hyper-V** or **Virtual Machine Platform**.

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
