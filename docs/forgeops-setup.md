# ForgeOps minikube setup (quick reference)

> **Full stack guide:** [forgeops-full-stack-setup.md](forgeops-full-stack-setup.md) — AM, IDM, DS, optional Gateway  
> **Official:** [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html) | [Quick deployment on minikube](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)

## Prerequisites

Install on your machine (see [ForgeOps third-party software requirements](https://docs.pingidentity.com/forgeops/2025.2/setup/software.html) in Ping docs):

| Tool | Purpose |
|------|---------|
| Docker Engine | Container runtime for minikube driver |
| minikube | Local Kubernetes cluster |
| kubectl | Kubernetes CLI |
| helm | Deploy identity-platform chart |
| kubens | Switch Kubernetes namespace |
| python3 | ForgeOps utility virtualenv |

**Hardware (minikube profile in official guide):** 3 CPUs, 9 GB RAM, 40 GB disk.

## Step 1 — Clone ForgeOps

```bash
git clone https://github.com/ForgeRock/forgeops.git
cd forgeops
git checkout 2026.2.1
```

> The official 2025.2 quick-start page references tag `2026.2.1` at time of writing.

## Step 2 — Start minikube

```bash
minikube start --cpus=3 --memory=9g --disk-size=40g --cni=true \
  --kubernetes-version=stable --addons=ingress,volumesnapshots,metrics-server \
  --driver=docker
```

Add hosts entry (adjust FQDN if you change it):

```text
127.0.0.1 forgeops.example.com
```

On Linux/macOS, edit `/etc/hosts`. On Windows, `C:\Windows\System32\drivers\etc\hosts`.

## Step 3 — Python venv for forgeops utility

```bash
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
./bin/forgeops configure
```

If you upgrade Python later:

```bash
rm -rf .venv && python3 -m venv .venv && ./bin/forgeops configure
```

## Step 4 — Deploy identity platform

Run these in the terminal where the venv is active.

### 4a. Cluster issuer

```bash
kubectl apply -f etc/resources/selfsigned-issuer.yaml
```

### 4b. Environment configuration

```bash
cd bin
./forgeops env --env-name my-env --fqdn forgeops.example.com \
  --cluster-issuer default-issuer --single-instance
```

Replace `forgeops.example.com` and `my-cluster-issuer` with your values.

### 4c. Namespace

```bash
kubectl create namespace my-namespace
kubens my-namespace
```

### 4d. Prerequisites

```bash
./forgeops prereqs
```

### 4e. Minikube tunnel (separate terminal)

```bash
sudo minikube tunnel
```

Leave this running. It binds ingress to localhost.

### 4f. Fast storage class

```bash
kubectl apply -f etc/resources/minikube-fast-storage-class.yaml
```

### 4g. Enable secret generator

```bash
cd bin
./forgeops env --env-name my-env --namespace my-namespace
```

### 4h. Helm install

```bash
helm upgrade --install identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops/ \
  --namespace my-namespace \
  --values ../helm/my-env/values.yaml
```

### 4i. Wait for pods

```bash
kubectl get pods -w
```

Deployment is ready when all pods show `Running` or `Completed`, and `READY` shows all containers up.

## Step 5 — Access admin UI

```bash
cd bin
./forgeops info | grep amadmin
```

Open: **https://forgeops.example.com/platform**

- Username: `amadmin`
- Password: output from `./forgeops info`

## One-command deploy (this repo)

```bash
./forgeops/scripts/install-prerequisites-ubuntu.sh
cp forgeops/config/env.example forgeops/config/env.local
./forgeops/scripts/deploy-full-stack.sh
# Terminal 2: sudo minikube tunnel
./forgeops/scripts/verify-stack.sh
```

See [forgeops-full-stack-setup.md](forgeops-full-stack-setup.md) for component map and URLs.

## Helper script (partial setup)

From the repo root:

```bash
chmod +x forgeops/scripts/setup-minikube.sh
./forgeops/scripts/setup-minikube.sh
```

Set environment variables first (see `forgeops/config/env.example`).

## Teardown

```bash
./forgeops/scripts/teardown.sh
```

## Next lab

After AM is up, continue with [SAML lab: AM as IdP](saml-lab-am-as-idp.md).

## Official references

- [Quick deployment on minikube](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)
- [Setup overview](https://docs.pingidentity.com/forgeops/2025.2/setup/overview.html)
- [Deployment overview](https://docs.pingidentity.com/forgeops/2025.2/deployment/overview.html)
