# Week 1 — ForgeOps home lab (Windows + WSL2)

**Time:** ~30 min/day  
**Host:** Windows (`C:\ciam`) + WSL Ubuntu (`/mnt/c/ciam`, ForgeOps clone `~/forgeops`)  
**FQDN:** `forgeops.example.com`  
**Outcome:** AM + IDM + PingDS running; login to Platform UI

> **Stop here each day** when the day’s Verify passes. Resume tomorrow.

---

## Day 1 — Prerequisites (WSL Ubuntu)

Open **Windows Terminal → Ubuntu** (prompt must be `$`, not `PS`).

```bash
cd /mnt/c/ciam
sed -i 's/\r$//' forgeops/scripts/*.sh forgeops/config/env.local
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/check-cgroup.sh
./forgeops/scripts/install-prerequisites-ubuntu.sh
```

**Verify:** `docker`, `minikube`, `kubectl`, `helm`, `python3` print versions.  
**Stop here.**

---

## Day 2 — Minikube + ForgeOps configure

```bash
cd /mnt/c/ciam
./forgeops/scripts/setup-forgerock.sh
```

If you already finished a partial deploy, continue from `~/forgeops` instead (see Day 3).

**Pitfalls:**
- PowerShell cannot run these scripts — use Ubuntu.
- Stale certs: `minikube delete --all --purge` then re-run.
- Traefik timeout: use `./forgeops prereqs --nginx` (script does this now).

**Verify:** `minikube status` shows Running.  
**Stop here.**

---

## Day 3 — Prereqs, tunnel, Helm deploy

**Terminal A — tunnel (leave open):**

```bash
sudo MINIKUBE_HOME=/home/jaya/.minikube \
  KUBECONFIG=/home/jaya/.kube/config \
  minikube tunnel
```

**Terminal B — deploy:**

```bash
cd ~/forgeops
source .venv/bin/activate
cd bin

./forgeops env --env-name my-env --fqdn forgeops.example.com \
  --cluster-issuer default-issuer --single-instance
kubectl create namespace my-namespace 2>/dev/null || true
kubens my-namespace
./forgeops prereqs --nginx
kubectl wait --for=condition=Established crd/clusterissuers.cert-manager.io --timeout=180s
kubectl apply -f ../etc/resources/selfsigned-issuer.yaml
kubectl apply -f ../etc/resources/minikube-fast-storage-class.yaml
./forgeops env --env-name my-env --namespace my-namespace

helm upgrade --install identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops/ \
  --namespace my-namespace \
  --values ../helm/my-env/values.yaml \
  --wait --timeout 30m
```

**Verify:**

```bash
kubectl get pods -n my-namespace
# All Running or Completed
./forgeops info | grep amadmin
```

**Stop here.**

---

## Day 4 — Hosts + login

**Windows hosts** (Admin Notepad → `C:\Windows\System32\drivers\etc\hosts`):

```text
127.0.0.1  forgeops.example.com
```

Browser (tunnel still running):

| URL | App |
|-----|-----|
| https://forgeops.example.com/platform | Platform UI |
| https://forgeops.example.com/am | AM console |
| https://forgeops.example.com/admin | IDM admin |
| https://forgeops.example.com/enduser | End-user UI |

Login: `amadmin` / password from `./forgeops info | grep amadmin`  
Accept the self-signed cert warning.

**Verify:** all four UIs load.  
**Stop here.**

---

## Day 5 — Understand DS

```bash
kubectl get statefulsets -n my-namespace
kubectl describe pod ds-idrepo-0 -n my-namespace | head -40
kubectl describe pod ds-cts-0 -n my-namespace | head -40
```

| Store | Role |
|-------|------|
| **ds-idrepo** | Identities / identity data |
| **ds-cts** | Core Token Service (sessions/tokens) |

**Resume bullet:** Deployed Ping AM/IDM/DS via ForgeOps on minikube (WSL2).  
**Stop here.**

---

## Day 6 — Verify script + local playground

```bash
cd /mnt/c/ciam
./forgeops/scripts/verify-stack.sh
```

Local clone to experiment (already present):

```bash
cd ~/forgeops
git checkout -b my-lab   # once
# edit helm/my-env/values.yaml then helm upgrade ...
```

Open in Cursor from Windows: `\\wsl$\Ubuntu\home\jaya\forgeops`

**Stop here.**

---

## Day 7 — Blog

Update `blog/drafts/01-forgeops-home-lab.md` with your real path (WSL, nginx not Traefik, FQDN `forgeops.example.com`).

**Next:** `labs/week-02-saml-sso/` — AM as SAML IdP.

---

## Quick reference (this laptop)

| Item | Value |
|------|-------|
| Lab repo | `C:\ciam` → `/mnt/c/ciam` |
| ForgeOps clone | `~/forgeops` (tag `2026.2.1`) |
| Namespace | `my-namespace` |
| FQDN | `forgeops.example.com` |
| Tunnel | `sudo MINIKUBE_HOME=/home/jaya/.minikube KUBECONFIG=/home/jaya/.kube/config minikube tunnel` |
