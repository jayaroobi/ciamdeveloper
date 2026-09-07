# CIAM Developer Lab

Hands-on lab for Ping Advanced Identity Software (ForgeRock AM/IDM) — SAML/SSO, ForgeOps, non-human identities, and Amazon Bedrock.

| Default | Value |
|---------|--------|
| FQDN | `forgeops.example.com` |
| ForgeOps git tag | `2026.2.1` |
| Namespace | `my-namespace` |
| Env name | `my-env` |

---

## Setup from Git

### 1. Clone this lab repo

```bash
git clone https://github.com/jayaroobi/ciamdeveloper.git
cd ciamdeveloper
git checkout cursor/forgeops-ciam-career-lab-fe67
```

**Windows (PowerShell):**

```powershell
cd C:\
git clone https://github.com/jayaroobi/ciamdeveloper.git ciam
cd C:\ciam
git checkout cursor/forgeops-ciam-career-lab-fe67
.\forgeops\scripts\init-local-windows.ps1
```

### 2. Where to run ForgeOps

| Environment | ForgeOps? | Notes |
|-------------|-----------|--------|
| **WSL2 Ubuntu + Docker Desktop** (recommended on Windows) | Yes | See below |
| Bare Linux / Ubuntu VM | Yes | Same bash scripts |
| Cursor Docker workspace | **No** | cgroup blocks minikube — use [docs/HANDS-ON.md](docs/HANDS-ON.md) for partial lab |
| Multipass | Fallback only | VirtualBox driver often broken on this laptop |

**Cursor workspace (partial lab — no ForgeOps AM):**

```bash
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/setup-workspace-hands-on.sh
cd apps/saml-service-provider && npm start   # http://localhost:3000
```

Full SSO needs AM in WSL — see [docs/HANDS-ON.md](docs/HANDS-ON.md).

### 3. Windows + WSL2 (recommended)

1. Install **Docker Desktop** (WSL2 backend) and start it.
2. Open **Windows Terminal → Ubuntu** (prompt must be `$`, not `PS C:\...>`).
3. Run:

```bash
cd /mnt/c/ciam          # or your clone path under /mnt/c/...
sed -i 's/\r$//' forgeops/scripts/*.sh forgeops/config/env.local 2>/dev/null || true
chmod +x forgeops/scripts/*.sh
cp -n forgeops/config/env.example forgeops/config/env.local

./forgeops/scripts/check-cgroup.sh
./forgeops/scripts/install-prerequisites-ubuntu.sh
./forgeops/scripts/setup-forgerock.sh
```

**PowerShell wrapper** (same flow via WSL):

```powershell
cd C:\ciam
.\forgeops\scripts\setup-forgerock-wsl.ps1
```

4. When prompted for tunnel, **second Ubuntu window:**

```bash
sudo MINIKUBE_HOME=$HOME/.minikube KUBECONFIG=$HOME/.kube/config minikube tunnel
```

5. **Windows hosts** (Admin Notepad → `C:\Windows\System32\drivers\etc\hosts`):

```text
127.0.0.1  forgeops.example.com
```

6. Open **https://forgeops.example.com/platform**  
   Password: `cd ~/forgeops/bin && source ../.venv/bin/activate && ./forgeops info | grep amadmin`

**Beginner guide (components + DS vs IG + steps):** [docs/forgeops-beginner-guide.md](docs/forgeops-beginner-guide.md)  
Lab walkthrough (day-by-day): [labs/week-01-forgeops-deploy/README.md](labs/week-01-forgeops-deploy/README.md)  
Cheat sheet: [LOCAL.md](LOCAL.md)

Official Ping docs:
- [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html)
- [Quick deployment on minikube](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)
- [Repositories](https://docs.pingidentity.com/forgeops/2025.2/start/repositories.html) — clone tag **`2026.2.1`**

---

## What `setup-forgerock.sh` does (step by step)

Main entry: `forgeops/scripts/setup-forgerock.sh`

| Step | Action |
|------|--------|
| 0 | Block Cursor Docker workspace; run `check-cgroup.sh` |
| 0 | Source `forgeops/config/env.local` (CRLF-safe) |
| 1 | `install-prerequisites-ubuntu.sh` — Docker, kubectl, Helm, minikube, kubens, python3 |
| 2 | Add `127.0.0.1 $FORGEOPS_FQDN` to Linux `/etc/hosts` |
| 3 | Clone `https://github.com/ForgeRock/forgeops.git` → `~/forgeops`, checkout tag `2026.2.1` |
| 4 | Start minikube (3 CPU / 9G / 40G, ingress + volumesnapshots + metrics-server). Purges broken clusters (stale certs) |
| 5 | `ensure-python-venv.sh` → create `.venv` → `forgeops configure` |
| 5 | `forgeops env` (FQDN + cluster issuer) |
| 5 | Create namespace, `kubens` |
| 5 | `forgeops prereqs --nginx` (cert-manager + nginx + secrets; avoids Traefik timeouts) |
| 5 | Wait for ClusterIssuer CRD → apply `selfsigned-issuer.yaml` |
| 5 | Apply `minikube-fast-storage-class.yaml` → `forgeops env --namespace` |
| 5 | Prompt for **minikube tunnel** (second terminal) |
| 6 | `helm upgrade --install identity-platform` from ForgeRock Helm repo |
| 7 | Save URLs + `amadmin` password → `forgeops/CREDENTIALS.local` |

Ping images/charts are pulled from Ping/ForgeRock registries during Helm/pod start. Your editable clone stays at `~/forgeops`.

---

## Scripts reference

### Deploy / setup

| Script | Purpose |
|--------|---------|
| `setup-forgerock.sh` | Full ForgeOps deploy (preferred) |
| `setup-forgerock-wsl.ps1` | PowerShell → runs setup inside WSL Ubuntu |
| `windows-forgerock.ps1` | Multipass VM launcher (fallback) |
| `init-local-windows.ps1` | Creates bash-safe `env.local` + `local-path.txt` |
| `install-prerequisites-ubuntu.sh` | Installs Docker, kubectl, Helm, minikube, kubens, python3 |
| `ensure-python-venv.sh` | Auto-installs `python3-venv` if missing |
| `deploy-full-stack.sh` | Deploy assuming tools + minikube already up |
| `setup-minikube.sh` / `setup-today.sh` | Alternate / combined flows |
| `deploy-ping-gateway.sh` | Optional PingGateway |

### Checks / teardown

| Script | Purpose |
|--------|---------|
| `check-cgroup.sh` | Fail fast if memory cgroup blocks minikube |
| `check-prerequisites.sh` | Tool versions + hosts entry |
| `verify-stack.sh` | Platform pods ready |
| `teardown.sh` | Tear down lab stack |
| `start-postgresql.sh` / `stop-postgresql.sh` / `verify-postgresql.sh` | Optional app DB |

### Hardening built into scripts

- CRLF-safe `env.local` sourcing (`sed` strip `\r`)
- `.gitattributes`: `forgeops/scripts/*.sh text eol=lf`
- Auto-install `python3-venv`
- Minikube purge on broken/stale certs
- `forgeops prereqs --nginx` (Traefik often times out on minikube)
- Issuer applied **after** cert-manager CRDs exist
- Multipass script uses full path to `multipass.exe` when not on PATH

---

## After install — daily use

```bash
# Tunnel (required for browser access)
sudo MINIKUBE_HOME=$HOME/.minikube KUBECONFIG=$HOME/.kube/config minikube tunnel

# Status / password
cd ~/forgeops && source .venv/bin/activate && cd bin
kubectl get pods -n my-namespace
./forgeops info | grep amadmin
```

| URL | App |
|-----|-----|
| https://forgeops.example.com/platform | Platform UI |
| https://forgeops.example.com/am | AM |
| https://forgeops.example.com/admin | IDM |
| https://forgeops.example.com/enduser | End-user UI |

---

## What's in this repo

| Path | Description |
|------|-------------|
| [labs/week-01-forgeops-deploy/](labs/week-01-forgeops-deploy/) | Week 1 lab (WSL + ForgeOps) |
| [labs/week-02-saml-sso/](labs/week-02-saml-sso/) | SAML SSO lab |
| [docs/forgeops-windows-setup.md](docs/forgeops-windows-setup.md) | Windows Multipass / WSL guide |
| [docs/forgeops-full-stack-setup.md](docs/forgeops-full-stack-setup.md) | Full stack reference |
| [docs/saml-lab-am-as-idp.md](docs/saml-lab-am-as-idp.md) | SAML IdP guide |
| [apps/saml-service-provider/](apps/saml-service-provider/) | Node.js SAML SP |
| [apps/oauth2-oidc-client/](apps/oauth2-oidc-client/) | OIDC comparison app |
| [apps/bedrock-nhi-assistant/](apps/bedrock-nhi-assistant/) | Bedrock + NHI demo |
| [.cursor/skills/forgeops-ciam-lab/](.cursor/skills/forgeops-ciam-lab/) | Cursor Agent skill |

## Cursor skill

Type `/forgeops-ciam-lab` in Agent chat or ask: *"What is today's 30-minute lab?"*

## Daily time budget

**30 minutes/day** — see [docs/30-min-daily-curriculum.md](docs/30-min-daily-curriculum.md).

## Stack components

| Component | Default deploy? | Notes |
|-----------|-----------------|-------|
| PingAM | Yes | SSO, SAML, OAuth2 |
| PingIDM | Yes | Provisioning |
| PingDS (idrepo + cts) | Yes | Identity directory (LDAP) |
| PostgreSQL | Optional | Separate app DB — `infra/postgresql/` |
| PingGateway | Optional | `deploy-ping-gateway.sh` |

## License

Lab scripts and apps: use freely. ForgeOps/Ping Docker images require [Ping license terms](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html).
