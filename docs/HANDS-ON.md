# Hands-on lab — where to run what

You have **two environments**. Use the right one for each task.

| Task | Cursor workspace (cloud) | Windows WSL2 Ubuntu |
|------|--------------------------|---------------------|
| Edit code & docs | Yes | Yes |
| PostgreSQL app DB | Yes (native) | Yes (Docker or native) |
| SAML SP app (`npm start`) | Yes | Yes |
| **Ping AM / IDM / PingDS** | **No** | **Yes** |
| SAML SSO end-to-end | Needs AM in WSL | Yes |

---

## Why ForgeOps cannot run in Cursor workspace

This workspace is a **Docker container**. Nested Docker and Kubernetes (minikube) are blocked:

```text
systemd-detect-virt: docker
```

Full Ping AM + IDM + PingDS needs **WSL2 on your Windows laptop**.

---

## Part 1 — Set up what works in Cursor (5 min)

In the Cursor agent terminal:

```bash
cd /workspace   # or your repo root
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/setup-workspace-hands-on.sh
```

This installs:

- PostgreSQL (native) with `ciam_lab` schema
- SAML SP dependencies + metadata file
- OAuth2 client app dependencies

---

## Part 2 — Deploy ForgeOps on Windows WSL (45–60 min)

On your **Windows laptop**:

1. Start **Docker Desktop** (whale icon steady).
2. Open **PowerShell**:

```powershell
cd C:\ciam
git pull origin cursor/forgeops-ciam-career-lab-fe67
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\forgeops\scripts\setup-forgerock-wsl.ps1
```

3. When prompted, open a **second Ubuntu** window:

```bash
sudo minikube tunnel
```

4. Add to Windows hosts file (Admin Notepad → `C:\Windows\System32\drivers\etc\hosts`):

```text
127.0.0.1  forgeops.example.com
```

5. Open: https://forgeops.example.com/platform  
   Login: `amadmin` / password from `./forgeops info | grep amadmin` inside WSL.

---

## Part 3 — SAML SSO hands-on (Week 2)

Once AM is running in WSL:

1. Follow `labs/week-02-saml-sso/README.md`
2. Import SP metadata from `apps/saml-service-provider/metadata/sp-metadata.xml` into AM
3. Start SAML SP (Cursor workspace or WSL):

```bash
cd apps/saml-service-provider
npm start
```

4. Browser: http://localhost:3000 → **Login with SAML**

---

## Quick commands

```bash
# Cursor workspace — PostgreSQL
./forgeops/scripts/start-postgresql-native.sh

# Cursor workspace — SAML SP
cd apps/saml-service-provider && npm start

# WSL — ForgeOps status
kubectl get pods -n my-namespace
./forgeops/scripts/verify-stack.sh

# WSL — tunnel (keep running)
sudo minikube tunnel
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| PowerShell says `chmod`/`sed` not found | You are in Windows PowerShell — use WSL Ubuntu |
| WSL timeout | `wsl --shutdown`, wait 10s, restart Docker Desktop |
| `domain threaded` in WSL | Use Multipass with Hyper-V — see `LOCAL.md` |
| SAML login fails | Export IdP metadata from AM; check Circle of Trust |
| PostgreSQL connection refused | Run `start-postgresql-native.sh` or `start-postgresql.sh` |
