# From scratch — Ping AM + IDM on new Windows laptop

**One script does everything** after you have WSL + Docker Desktop installed.

---

## Quick start (copy-paste)

### First time — run as Administrator

Open **PowerShell as Administrator**:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
cd C:\
git clone https://github.com/jayaroobi/ciamdeveloper.git ciam
cd C:\ciam
git checkout cursor/forgeops-ciam-career-lab-fe67
.\forgeops\scripts\setup-from-scratch.ps1
```

The script will:

1. Install Git (if missing)
2. Install WSL2 + Ubuntu (if missing — **reboot** if prompted)
3. Check Docker Desktop
4. Clone/update repo + local config
5. Add `forgeops.example.com` to hosts file
6. Deploy **Ping AM + IDM + PingDS** inside WSL (~45–60 min)

### After reboot (WSL user created, Docker Desktop installed)

```powershell
cd C:\ciam
git pull origin cursor/forgeops-ciam-career-lab-fe67
.\forgeops\scripts\setup-from-scratch.ps1 -DeployOnly
```

### During deploy — second terminal (required)

When the script pauses, open **Windows Terminal → Ubuntu**:

```bash
sudo minikube tunnel
```

Leave it running. Press Enter in the first window.

---

## What you get

| Product | URL |
|---------|-----|
| **Ping AM** | https://forgeops.example.com/am |
| **Ping IDM** | https://forgeops.example.com/admin |
| Platform | https://forgeops.example.com/platform |

Login: `amadmin` — password in `C:\ciam\forgeops\CREDENTIALS.local`

---

## Prerequisites checklist

Before running, ensure:

- [ ] **16 GB RAM** laptop (9 GB for minikube)
- [ ] **Virtualization enabled** in BIOS (Intel VT-x / AMD-V)
- [ ] **Docker Desktop** installed with WSL2 backend
- [ ] Docker memory set to **10 GB+** (Settings → Resources)
- [ ] WSL integration enabled for **Ubuntu**

---

## Manual steps if script stops early

| Script says | You do |
|-------------|--------|
| Reboot + create Ubuntu user | Reboot, open Ubuntu, set username/password |
| Install Docker Desktop | https://www.docker.com/products/docker-desktop/ |
| Add hosts manually | Admin Notepad → `C:\Windows\System32\drivers\etc\hosts` → `127.0.0.1 forgeops.example.com` |
| Open second terminal | `sudo minikube tunnel` in Ubuntu |

---

## Verify

In Ubuntu:

```bash
cd /mnt/c/ciam
./forgeops/scripts/verify-stack.sh
kubectl get pods -n my-namespace
```

All pods **Running** or **Completed**.

---

## Daily restart (after first setup)

```powershell
# 1. Start Docker Desktop
# 2. Ubuntu terminal:
minikube start
sudo minikube tunnel   # second window
# 3. Browser: https://forgeops.example.com/am
```

Stop: `minikube stop` + Ctrl+C tunnel

---

## Troubleshooting

See [new-laptop-setup.md](new-laptop-setup.md) for full troubleshooting table.

| Error | Fix |
|-------|-----|
| `chmod` not recognized | Use Ubuntu, not PowerShell |
| Docker not in WSL | Docker Desktop → WSL Integration → Ubuntu ON |
| WSL timeout | `wsl --shutdown`, restart Docker, `wsl -d Ubuntu` |
| Page won't load | Is tunnel running? Hosts file set? |

---

## Next lab

[Week 2 — SAML SSO](../labs/week-02-saml-sso/README.md)
