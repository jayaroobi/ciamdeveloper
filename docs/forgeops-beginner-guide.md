# ForgeOps beginner guide — prerequisites, components, steps

> For Windows + WSL2 (this laptop).  
> Official docs: [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html) · [minikube quick start](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)

---

## Did we set up DS and IG?

| Component | Set up? | What it is |
|-----------|---------|------------|
| **PingDS (Directory Server)** | **Yes** | Identity directory (LDAP). You have **two**: `ds-idrepo` (identities) and `ds-cts` (tokens/sessions). |
| **PingGateway (IG)** | **No** | Optional reverse proxy / policy enforcement point. **Not** part of the default Helm install. |

Default stack you installed = **AM + IDM + DS + UIs**.  
IG is optional later: `./forgeops/scripts/deploy-ping-gateway.sh`.

---

## Components (simple picture)

```text
Browser
   │
   ▼
Ingress (nginx) + TLS (cert-manager)
   │
   ├─ /platform, /am     →  PingAM     (login, SSO, SAML, OAuth)
   ├─ /admin             →  PingIDM    (users, provisioning)
   ├─ /enduser           →  End-user UI
   │
   └─ AM & IDM talk to:
         ├─ PingDS idrepo  (who are the users?)
         └─ PingDS cts     (tokens / sessions)
```

| Name | Beginner meaning | In your cluster |
|------|------------------|-----------------|
| **PingAM** | Authentication / SSO “front door” | `am` pod |
| **PingIDM** | User lifecycle / admin of identities | `idm` pod |
| **PingDS idrepo** | Database of identities (LDAP) | `ds-idrepo-0` |
| **PingDS cts** | Token/session store | `ds-cts-0` |
| **Amster** | One-time job that loads AM config | job (then Completed) |
| **Login / Admin / End-user UI** | Web consoles | `login-ui`, `admin-ui`, `end-user-ui` |
| **cert-manager** | Makes HTTPS certificates | prereq |
| **ingress-nginx** | Routes forgeops.example.com to pods | prereq (nginx, not Traefik) |
| **PingGateway (IG)** | Optional gateway in front of apps | **not installed** |

**Not the same as PostgreSQL:** PingDS is the ForgeOps identity store. PostgreSQL (optional in this repo) is only for your own app/audit labs.

---

## Prerequisites

### Hardware

| Resource | Need |
|----------|------|
| CPU | 3+ cores for minikube |
| RAM | ~9 GB for minikube + some left for Windows |
| Disk | ~40 GB free |
| OS | Windows 10/11 + WSL2 Ubuntu + Docker Desktop |

### Software (installed by our scripts)

| Tool | Why |
|------|-----|
| Docker Desktop | Runs containers (minikube driver) |
| WSL2 Ubuntu | Where bash / ForgeOps scripts run |
| minikube | Local Kubernetes |
| kubectl | Talk to the cluster |
| Helm | Install the identity-platform chart |
| kubens | Switch Kubernetes namespace |
| python3 + venv | `forgeops` CLI |

### Accounts / license

- Ping ForgeOps images need a valid Ping license/subscription (see [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html)).
- GitHub: public clone of [ForgeRock/forgeops](https://github.com/ForgeRock/forgeops) tag **`2026.2.1`**.

### Important Windows rules

1. Use **Ubuntu** terminal (`jaya@LAPTOP-...:$`), **not** PowerShell, for bash scripts.
2. Lab repo: `C:\ciam` → in WSL: `/mnt/c/ciam`
3. ForgeOps clone: `~/forgeops` (under your Linux home)
4. Cursor’s cloud Docker workspace **cannot** run minikube (cgroup). Use WSL on the laptop.

---

## Setup steps (beginner path)

### A. First time — from Git

**PowerShell (once):**

```powershell
cd C:\
git clone https://github.com/jayaroobi/ciamdeveloper.git ciam
cd C:\ciam
git checkout cursor/forgeops-ciam-career-lab-fe67
.\forgeops\scripts\init-local-windows.ps1
```

**Ubuntu (WSL):**

```bash
cd /mnt/c/ciam
sed -i 's/\r$//' forgeops/scripts/*.sh
chmod +x forgeops/scripts/*.sh
cp -n forgeops/config/env.example forgeops/config/env.local

./forgeops/scripts/check-cgroup.sh
./forgeops/scripts/install-prerequisites-ubuntu.sh
./forgeops/scripts/setup-forgerock.sh
```

What the main script does for you:

1. Install tools (if missing)  
2. Clone ForgeOps `2026.2.1` → `~/forgeops`  
3. Start minikube  
4. Create Python venv + `forgeops configure`  
5. Install prereqs (**nginx** + cert-manager + secrets)  
6. Apply TLS issuer + fast storage  
7. Ask you to start **minikube tunnel**  
8. Helm install **identity-platform** (AM + IDM + DS + UIs)  
9. Print `amadmin` password  

### B. Second terminal — tunnel (keep open)

```bash
sudo MINIKUBE_HOME=$HOME/.minikube KUBECONFIG=$HOME/.kube/config minikube tunnel
```

### C. Windows hosts file (Admin Notepad)

`C:\Windows\System32\drivers\etc\hosts`:

```text
127.0.0.1  forgeops.example.com
```

### D. Login

| URL | App |
|-----|-----|
| https://forgeops.example.com/platform | Platform dashboard |
| https://forgeops.example.com/am | AM console |
| https://forgeops.example.com/admin | IDM admin |
| https://forgeops.example.com/enduser | End-user UI |

```bash
cd ~/forgeops && source .venv/bin/activate && cd bin
./forgeops info | grep amadmin
```

User: **`amadmin`**  
Password: from the command above (does **not** rotate every day).

---

## After reboot / next day

Minikube stops when the PC sleeps. Start again:

```bash
# Ubuntu
minikube start
# then tunnel again
sudo MINIKUBE_HOME=$HOME/.minikube KUBECONFIG=$HOME/.kube/config minikube tunnel

kubectl get pods -n my-namespace
```

You usually do **not** need to re-run Helm unless you deleted the cluster (`minikube delete`).

---

## Optional next pieces

| Want | Command / lab |
|------|----------------|
| **PingGateway (IG)** | `./forgeops/scripts/deploy-ping-gateway.sh` |
| **PostgreSQL** (app DB, not DS) | `./forgeops/scripts/start-postgresql.sh` |
| **SAML practice** | `labs/week-02-saml-sso/` |
| **Verify stack** | `./forgeops/scripts/verify-stack.sh` |

---

## Quick troubleshooting

| Problem | Fix |
|---------|-----|
| `sed` / `chmod` in PowerShell | Wrong shell — open **Ubuntu** |
| Traefik timeout | Scripts use `forgeops prereqs --nginx` |
| Tunnel “profile not found” with sudo | Use `MINIKUBE_HOME` + `KUBECONFIG` as above |
| Site not opening | Tunnel must be running + hosts entry |
| “Not secure” in browser | Normal with self-signed cert — continue |
| Cluster unreachable | `minikube start` then tunnel |

---

## Related docs in this repo

| Doc | Use when |
|-----|----------|
| [LOCAL.md](../LOCAL.md) | Short Windows cheat sheet |
| [README.md](../README.md) | Scripts list + setup from Git |
| [labs/week-01-forgeops-deploy/README.md](../labs/week-01-forgeops-deploy/README.md) | Day-by-day lab |
| [forgeops-windows-setup.md](forgeops-windows-setup.md) | Multipass / WSL detail |
| [forgeops-full-stack-setup.md](forgeops-full-stack-setup.md) | Deeper full-stack notes |
