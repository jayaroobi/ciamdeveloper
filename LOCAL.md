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

## Deploy ForgeRock (recommended: WSL2)

Docker Desktop + WSL Ubuntu are already working on this laptop. Multipass is optional fallback.

**From PowerShell (easiest):**

```powershell
cd C:\ciam
.\forgeops\scripts\setup-forgerock-wsl.ps1
```

**Or open Windows Terminal → Ubuntu** (prompt must be `$`, not `PS C:\ciam>`), then:

```bash
cd /mnt/c/ciam
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/check-cgroup.sh
./forgeops/scripts/install-prerequisites-ubuntu.sh
./forgeops/scripts/setup-forgerock.sh
```

**Second Ubuntu window** (when prompted for tunnel):

```bash
sudo MINIKUBE_HOME=$HOME/.minikube KUBECONFIG=$HOME/.kube/config minikube tunnel
```

## Hosts file

Add to `C:\Windows\System32\drivers\etc\hosts` (Admin):

```text
127.0.0.1  forgeops.example.com
```

## Open ForgeRock

https://forgeops.example.com/platform

Password: `cd ~/forgeops/bin && source ../.venv/bin/activate && ./forgeops info | grep amadmin`

## Alternate: Multipass

```powershell
cd C:\ciam
git pull origin cursor/forgeops-ciam-career-lab-fe67
.\forgeops\scripts\diagnose-multipass-windows.ps1   # if launch fails
.\forgeops\scripts\windows-forgerock.ps1
```

Mounts are **not used** — repo is cloned via git inside the VM.

| Error | Meaning |
|-------|---------|
| `Mounts are disabled on this installation of Multipass` | Expected — script uses git clone in VM |
| `Could not generate a new UUID` | Multipass cannot find Hyper-V or VirtualBox |

**Hyper-V** (Windows Pro, Admin PowerShell): `multipass set local.driver=hyperv`  
**VirtualBox** (Home): install VirtualBox, add to System PATH, `multipass set local.driver=virtualbox`
