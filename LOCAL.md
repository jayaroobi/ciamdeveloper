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
.\forgeops\scripts\windows-forgerock.ps1
```

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
