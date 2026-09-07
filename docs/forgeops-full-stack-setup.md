# ForgeOps full stack — local setup (AM, IDM, DS, Gateway)

> **Official entry point:** [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html)  
> **Minikube quick start:** [Quick deployment on minikube](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)  
> **Use case:** Demo / development only — not production.

## What gets deployed

The `identity-platform` Helm chart deploys the **Ping Advanced Identity Software** stack on Kubernetes.

| Component | Kubernetes workload | Role |
|-----------|---------------------|------|
| **PingAM** (Access Management) | `am` deployment | SSO, SAML/OIDC, policies, journeys |
| **PingIDM** (Identity Management) | `idm` deployment | Provisioning, workflows, managed objects |
| **PingDS — idrepo** | `ds-idrepo` StatefulSet | Identity + config **directory database** (shared AM/IDM repo) |
| **PingDS — cts** | `ds-cts` StatefulSet | Core Token Service store (OAuth/SAML tokens, sessions) |
| **Amster** | Job | Loads AM configuration into AM |
| **Login UI** | deployment | Platform login at `/platform` |
| **Admin UI** | deployment | IDM admin at `/admin` |
| **End-user UI** | deployment | Self-service at `/enduser` |
| **cert-manager, ingress-nginx** | prereqs | TLS + routing (installed by `./forgeops prereqs`) |

> **Database note:** ForgeOps uses **PingDS** (LDAP directory) for identity — not PostgreSQL.  
> For a **separate PostgreSQL** app database (audit logs, app data), see [postgresql-lab-setup.md](postgresql-lab-setup.md).

> **PingGateway (IG):** **Not deployed by default.** The [ForgeOps README](https://github.com/ForgeRock/forgeops/blob/main/README.md) states IG is optional. See [Optional: deploy PingGateway](#optional-deploy-pinggateway) below.

## License reminder

From the official [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html) page: installing ForgeOps Docker images requires a valid Ping license agreement or subscription terms.

## Hardware (official minikube profile)

| Resource | Minimum |
|----------|---------|
| CPU | 3 cores |
| RAM | 9 GB |
| Disk | 40 GB free |

Run on your **local machine** (laptop/workstation with Docker). This cloud VM cannot run minikube due to nested Docker overlay limits.

## Optional: PostgreSQL (application database)

Separate from PingDS — for app data and SSO audit logs:

```bash
./forgeops/scripts/start-postgresql.sh
./forgeops/scripts/verify-postgresql.sh
```

Guide: [postgresql-lab-setup.md](postgresql-lab-setup.md)

## One-command setup (Ubuntu / Linux)

```bash
# 1. Install prerequisites (Docker, minikube, kubectl, helm, kubens)
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/install-prerequisites-ubuntu.sh

# 2. Log out and back in (docker group), or: newgrp docker

# 3. Configure
cp forgeops/config/env.example forgeops/config/env.local
# Edit FORGEOPS_REPO path if needed

# 4. Deploy full stack
./forgeops/scripts/deploy-full-stack.sh
```

In a **second terminal**, keep tunnel running:

```bash
sudo minikube tunnel
```

## Manual step-by-step

### 1. Prerequisites

```bash
./forgeops/scripts/install-prerequisites-ubuntu.sh
```

| Tool | Check |
|------|-------|
| Docker | `docker run hello-world` |
| minikube | `minikube version` |
| kubectl | `kubectl version --client` |
| helm | `helm version` |
| kubens | `kubens` |
| python3 | `python3 --version` |

### 2. Hosts file

```bash
./forgeops/scripts/add-hosts-entry.sh
# Adds: 127.0.0.1 forgeops.example.com
```

### 3. Clone ForgeOps

```bash
git clone https://github.com/ForgeRock/forgeops.git ~/forgeops
cd ~/forgeops
git checkout 2026.2.1
```

### 4. Start minikube

```bash
minikube start --cpus=3 --memory=9g --disk-size=40g --cni=true \
  --kubernetes-version=stable --addons=ingress,volumesnapshots,metrics-server \
  --driver=docker
```

### 5. Python venv

```bash
python3 -m venv .venv
source .venv/bin/activate
./bin/forgeops configure
```

### 6. Configure environment + deploy

```bash
kubectl apply -f etc/resources/selfsigned-issuer.yaml

cd bin
./forgeops env --env-name my-env --fqdn forgeops.example.com \
  --cluster-issuer default-issuer --single-instance

kubectl create namespace my-namespace
kubens my-namespace

./forgeops prereqs
kubectl apply -f ../etc/resources/minikube-fast-storage-class.yaml
./forgeops env --env-name my-env --namespace my-namespace

# Second terminal: sudo minikube tunnel

helm upgrade --install identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops/ \
  --namespace my-namespace \
  --values ../helm/my-env/values.yaml
```

### 7. Verify all pods

```bash
./forgeops/scripts/verify-stack.sh
```

Expected pods (single-instance): `am`, `idm`, `ds-idrepo-0`, `ds-cts-0`, `login-ui`, `admin-ui`, `end-user-ui`, plus completed jobs `amster`, `ds-set-passwords`, `keystore-create`.

## Access URLs

Replace `forgeops.example.com` with your FQDN.

| Service | URL |
|---------|-----|
| Platform login | https://forgeops.example.com/platform |
| PingAM console | https://forgeops.example.com/am |
| PingIDM admin | https://forgeops.example.com/admin |
| End-user UI | https://forgeops.example.com/enduser |

### Admin password

```bash
cd ~/forgeops/bin
source ../.venv/bin/activate
./forgeops info | grep amadmin
```

- Username: `amadmin`
- Password: from command output

## Optional: deploy PingGateway

PingGateway uses a **separate Helm chart** (`ping-gateway`). Deploy after identity-platform is healthy.

```bash
./forgeops/scripts/deploy-ping-gateway.sh
```

Default IG URL pattern: `https://forgeops.example.com/ig` (depends on your values overlay).

See chart: https://github.com/ForgeRock/forgeops/tree/main/charts/ping-gateway

## Teardown

```bash
./forgeops/scripts/teardown.sh
minikube delete   # optional — removes cluster entirely
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `forgeops.example.com` not reachable | Ensure `minikube tunnel` is running |
| Pods stuck Pending | Check storage class: `kubectl get sc` — need `fast` |
| AM not configured | Wait for `amster` job to complete: `kubectl get jobs` |
| DS password errors | Re-run: `helm upgrade` after `./forgeops env --namespace ...` |
| Docker permission denied | `sudo usermod -aG docker $USER && newgrp docker` |

Official troubleshooting: https://docs.pingidentity.com/forgeops/latest/troubleshoot/overview.html

## Next: SAML hands-on

Once AM is up → [SAML lab: AM as IdP](saml-lab-am-as-idp.md)

## References

- [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html)
- [Quick deployment on minikube](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)
- [UI and API access](https://docs.pingidentity.com/forgeops/latest/deploy/access.html)
- [ForgeOps GitHub README](https://github.com/ForgeRock/forgeops/blob/main/README.md)
