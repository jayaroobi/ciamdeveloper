# ForgeOps on a cloud VM (when your local workspace is containerized)

If `./forgeops/scripts/check-cgroup.sh` reports **domain threaded** or **inside docker**, minikube cannot run in your Cursor workspace. Use a **real Linux VM** instead.

## Why

Your workspace shows:

```text
cgroup.type: domain threaded
subtree_control: cpuset cpu pids   ← memory NOT delegated
systemd-detect-virt: docker       ← you are inside a container
```

RAM is fine (14 GB free). The **memory cgroup controller** is not available — minikube passes `--memory=4g` to Docker and it fails.

## Option 1 — Multipass VM on your physical machine (recommended)

If you have a Windows/Mac/Linux **host** with Multipass:

```bash
# On HOST (not Cursor container terminal)
multipass launch --name forgeops-lab --cpus 4 --memory 9G --disk 40G
multipass shell forgeops-lab

# Inside VM:
sudo apt update && sudo apt install -y docker.io git python3 python3-venv
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
# ... continue with setup-today.sh
git clone https://github.com/jayaroobi/ciamdeveloper.git
cd ciamdeveloper && ./forgeops/scripts/setup-today.sh
```

## Option 2 — Oracle Cloud free ARM VM

1. Create Ubuntu 24.04 VM (4 OCPU, 24 GB RAM — free tier)
2. SSH in
3. Run `./forgeops/scripts/install-prerequisites-ubuntu.sh`
4. Run `./forgeops/scripts/setup-today.sh`

Official ForgeOps also supports AWS/GCP/Azure:
- https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html

## Option 3 — Keep using workspace for non-K8s labs

These work in your current Cursor workspace:

| Works here | Does not work here |
|------------|-------------------|
| PostgreSQL (`start-postgresql.sh`) | minikube / ForgeOps |
| SAML SP app (`npm start`) | Ping AM / IDM / PingDS |
| Blog writing, curriculum | Full SSO test (needs AM) |

Deploy AM on a VM, then point SAML SP at the VM FQDN.

## Verify any environment before deploy

```bash
./forgeops/scripts/check-cgroup.sh
```

Must show: **Environment OK for minikube**
