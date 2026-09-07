# New laptop — Ping AM + IDM from scratch

Use this on a **fresh Windows laptop** to deploy **Ping Access Management (AM)** and **Ping Identity Management (IDM)** via ForgeOps.

> **Time:** ~1 hour first deploy (mostly waiting for images)  
> **RAM needed:** 16 GB laptop minimum (9 GB for minikube + Windows overhead)  
> **Not supported:** Cursor cloud workspace, PowerShell-only (must use WSL Ubuntu)

---

## What you get after setup

| Product | URL | Purpose |
|---------|-----|---------|
| **Platform UI** | https://forgeops.example.com/platform | Login hub |
| **Ping AM** | https://forgeops.example.com/am | SSO, SAML, OAuth, journeys |
| **Ping IDM** | https://forgeops.example.com/admin | Workflows, provisioning, managed users |
| **End-user UI** | https://forgeops.example.com/enduser | Self-service |
| **PingDS** | (internal) | LDAP identity store for AM + IDM |

Login: `amadmin` + password from `./forgeops info` (saved to `forgeops/CREDENTIALS.local`).

---

## Step 0 — Enable virtualization (BIOS)

Before anything else:

1. Reboot → enter BIOS (often F2 / Del / F10)
2. Enable **Intel VT-x** or **AMD-V**
3. Save and boot Windows

Without this, Docker/WSL/minikube will fail.

---

## Step 1 — Install software (one time)

Run **PowerShell as Administrator**:

### 1a. Git

```powershell
winget install Git.Git
```

### 1b. WSL2 + Ubuntu

```powershell
wsl --install -d Ubuntu-24.04
```

Reboot if prompted. Open **Ubuntu** from Start menu — create your Linux username and password (remember it for `sudo`).

### 1c. Docker Desktop

1. Download: https://www.docker.com/products/docker-desktop/
2. Install with **WSL2 backend** enabled
3. Docker Desktop → **Settings → Resources → Memory → 10 GB** (or more)
4. **Settings → Resources → WSL Integration → enable Ubuntu-24.04**
5. Start Docker Desktop — wait until the whale icon is steady (not "starting")

### 1d. Cursor (optional, for editing)

Download from https://cursor.com — clone/open repo at `C:\ciam`.

---

## Step 2 — Clone lab repo

**PowerShell** (normal, not Admin):

```powershell
cd C:\
git clone https://github.com/jayaroobi/ciamdeveloper.git ciam
cd C:\ciam
git checkout cursor/forgeops-ciam-career-lab-fe67
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\forgeops\scripts\init-local-windows.ps1
```

---

## Step 3 — Verify WSL is ready

Open **Windows Terminal → Ubuntu** (prompt must look like `yourname@...:~$`, **not** `PS C:\...>`):

```bash
cd /mnt/c/ciam
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/check-cgroup.sh
```

Must say: **Environment OK for minikube**.

If it says `domain threaded` or fails, see [forgeops-windows-setup.md](forgeops-windows-setup.md) Multipass fallback.

---

## Step 4 — Deploy AM + IDM (ForgeOps)

### Option A — PowerShell wrapper (easiest)

```powershell
cd C:\ciam
.\forgeops\scripts\setup-forgerock-wsl.ps1
```

### Option B — Manual in Ubuntu

```bash
cd /mnt/c/ciam
sed -i 's/\r$//' forgeops/scripts/*.sh forgeops/config/env.local
./forgeops/scripts/install-prerequisites-ubuntu.sh
# If docker permission denied: newgrp docker   (or close/reopen Ubuntu)
./forgeops/scripts/setup-forgerock.sh
```

**When the script pauses for tunnel** — open a **second Ubuntu** window:

```bash
sudo minikube tunnel
```

Leave that window open. Press Enter in the first window to continue.

Deploy takes **45–60 minutes** first time (pulls Docker images for AM, IDM, PingDS).

---

## Step 5 — Windows hosts file

**Notepad as Administrator** → open:

`C:\Windows\System32\drivers\etc\hosts`

Add:

```text
127.0.0.1  forgeops.example.com
```

Save.

---

## Step 6 — Log in to AM and IDM

Browser (tunnel must still be running):

| Console | URL |
|---------|-----|
| Platform | https://forgeops.example.com/platform |
| **AM admin** | https://forgeops.example.com/am |
| **IDM admin** | https://forgeops.example.com/admin |

Get password (Ubuntu):

```bash
cd ~/forgeops/bin
source ../.venv/bin/activate
./forgeops info | grep amadmin
```

Accept the self-signed certificate warning.

Also saved at: `/mnt/c/ciam/forgeops/CREDENTIALS.local`

---

## Step 7 — Verify everything is running

```bash
cd /mnt/c/ciam
./forgeops/scripts/verify-stack.sh
kubectl get pods -n my-namespace
```

All pods should be **Running** or **Completed**.

Expected workloads: `am`, `idm`, `ds-idrepo`, `ds-cts`, UIs, `amster` job.

---

## Daily use (after first setup)

**Start lab session:**

1. Start Docker Desktop
2. Ubuntu terminal: `multipass start` not needed — use:
   ```bash
   minikube start   # if stopped
   sudo minikube tunnel   # second window, leave open
   ```
3. Open https://forgeops.example.com/am or `/admin`

**Stop lab (free RAM):**

```bash
minikube stop
# Ctrl+C the tunnel window
```

---

## Troubleshooting (new laptop)

| Problem | Fix |
|---------|-----|
| `wsl --install` fails | Windows Update → enable "Virtual Machine Platform" |
| Docker "WSL integration" greyed out | Update WSL: `wsl --update`, reboot |
| `HCS_E_CONNECTION_TIMEOUT` | `wsl --shutdown`, restart Docker Desktop, `wsl -d Ubuntu` |
| Forgot WSL password | PowerShell: `wsl -d Ubuntu -u root` then `passwd youruser` |
| `chmod`/`sed` not recognized | You are in PowerShell — switch to Ubuntu |
| `domain threaded` in WSL | Try Multipass — see `LOCAL.md` |
| AM/IDM page won't load | Is `sudo minikube tunnel` running? Hosts file correct? |
| Pods stuck Pending | `free -h` in WSL — need ~9 GB free; increase Docker memory |

---

## Next — hands-on labs

1. **Week 1 done** when AM + IDM login works — [labs/week-01-forgeops-deploy](../labs/week-01-forgeops-deploy/README.md)
2. **Week 2 SAML** — AM as IdP — [labs/week-02-saml-sso](../labs/week-02-saml-sso/README.md)
3. Full reference — [forgeops-full-stack-setup.md](forgeops-full-stack-setup.md)

---

## Official Ping docs

- [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html)
- [Minikube quick start](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)
- ForgeOps git tag: **2026.2.1**
