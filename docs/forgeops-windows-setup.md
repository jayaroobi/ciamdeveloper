# ForgeOps on Windows — your local setup

Your **Cursor workspace runs inside Docker**, so minikube fails there (`domain threaded` cgroup).  
Run ForgeOps on your **physical Windows machine** using one of the options below.

> **Goal:** Ping AM + IDM + PingDS locally for SAML/SSO hands-on practice.

---

## Pick an option

| Option | Best for | RAM needed | Difficulty |
|--------|----------|------------|------------|
| **A — Multipass VM** | Most reliable, cleanest | 9 GB for VM | Easy |
| **B — WSL2 + Docker Desktop** | Daily dev workflow | 9 GB for WSL | Medium |

**Recommendation:** Start with **Option A (Multipass)** if Option B hits cgroup errors.

---

## Option A — Multipass VM (recommended)

Multipass runs a real Ubuntu VM on Windows — proper cgroups, minikube works.

### Step 1 — Install Multipass

1. Download: https://multipass.run/install
2. Or with winget:
   ```powershell
   winget install Canonical.Multipass
   ```
3. Restart PowerShell after install.

### Step 2 — Create VM

Open **PowerShell** (not Cursor terminal):

```powershell
multipass launch --name forgeops-lab --cpus 4 --memory 9G --disk 40G
multipass list
```

### Step 3 — Shell into VM

```powershell
multipass shell forgeops-lab
```

You are now in a **real Linux VM**. Verify cgroup:

```bash
cat /sys/fs/cgroup/cgroup.type
# Should NOT say "domain threaded" — expect "domain" or "domain hybrid"
free -h
```

### Step 4 — Install prerequisites inside VM

```bash
sudo apt update
sudo apt install -y docker.io git python3 python3-venv curl

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# kubens
sudo apt install -y kubectx

sudo usermod -aG docker $USER
newgrp docker
```

### Step 5 — Clone lab repo and deploy

```bash
git clone https://github.com/jayaroobi/ciamdeveloper.git
cd ciamdeveloper
git checkout cursor/forgeops-ciam-career-lab-fe67

chmod +x forgeops/scripts/*.sh
./forgeops/scripts/check-cgroup.sh    # must pass
./forgeops/scripts/setup-today.sh 2>&1 | tee setup-today.log
```

**Terminal 2 inside VM** (when prompted):

```bash
sudo minikube tunnel
```

### Step 6 — Access from Windows browser

Get VM IP:

```powershell
# In PowerShell on Windows
multipass info forgeops-lab
```

Add to `C:\Windows\System32\drivers\etc\hosts` (Run Notepad as Administrator):

```text
<VM-IP>  forgeops.example.com
```

Open: https://forgeops.example.com/platform  
Password: see `forgeops/CREDENTIALS.local` inside VM.

### Multipass useful commands

```powershell
multipass stop forgeops-lab      # stop VM
multipass start forgeops-lab     # start VM
multipass delete forgeops-lab    # delete VM
```

---

## Option B — WSL2 + Docker Desktop

Use this if you prefer WSL2 as your daily Linux environment.

### Step 1 — Enable WSL2

PowerShell as Administrator:

```powershell
wsl --install -d Ubuntu-24.04
```

Reboot if prompted. Set up Ubuntu username/password.

### Step 2 — Install Docker Desktop

1. Download: https://www.docker.com/products/docker-desktop/
2. Install and enable **WSL2 integration** for Ubuntu-24.04
3. Settings → Resources → Memory: set **至少 10 GB**

### Step 3 — Open WSL2 Ubuntu terminal

**Important:** Use **Windows Terminal → Ubuntu**, NOT the Cursor cloud workspace terminal.

```bash
cat /sys/fs/cgroup/cgroup.type
./forgeops/scripts/check-cgroup.sh   # after cloning repo
```

If check passes:

```bash
git clone https://github.com/jayaroobi/ciamdeveloper.git
cd ciamdeveloper
git checkout cursor/forgeops-ciam-career-lab-fe67
chmod +x forgeops/scripts/*.sh
./forgeops/scripts/install-prerequisites-ubuntu.sh
./forgeops/scripts/setup-today.sh 2>&1 | tee setup-today.log
```

Terminal 2:

```bash
sudo minikube tunnel
```

### Step 4 — hosts file on Windows

```text
127.0.0.1  forgeops.example.com
```

Add to `C:\Windows\System32\drivers\etc\hosts` (Administrator Notepad).

Open: https://forgeops.example.com/platform

### If WSL2 fails cgroup check

WSL2 sometimes shows `domain threaded`. Fall back to **Option A (Multipass)**.

---

## What stays in Cursor workspace

Your Cursor Docker workspace is still useful for:

| Task | Where |
|------|-------|
| PostgreSQL lab | Cursor workspace (already works) |
| SAML SP code editing | Cursor |
| Blog drafts, curriculum | Cursor |
| **ForgeOps AM/IDM/DS** | **Multipass VM or WSL2** |

After AM is running in VM, edit SAML SP `.env` to point at `forgeops.example.com` (via VM IP in hosts).

---

## Quick verification checklist

Before `setup-today.sh`, all must pass:

```bash
./forgeops/scripts/check-cgroup.sh     # Environment OK
./forgeops/scripts/check-prerequisites.sh
docker run hello-world
free -h                                 # 9GB+ available
```

---

## Hardware summary (your Windows laptop)

| Resource | ForgeOps needs |
|----------|----------------|
| RAM | 9 GB for VM/WSL + 4 GB for Windows |
| CPU | 4 cores recommended |
| Disk | 40 GB free |
| OS | Windows 10/11 with virtualization enabled |

Enable virtualization in BIOS if Multipass/Hyper-V fails.

---

## Next after ForgeOps is up

1. `labs/week-02-saml-sso/README.md` — SAML SSO lab
2. Import `apps/saml-service-provider/metadata/sp-metadata.xml` into AM
3. Blog: `blog/drafts/02-saml-am-idp.md`

---

## References

- [ForgeOps Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html)
- [ForgeOps minikube quick start](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)
- Multipass: https://multipass.run/
