---
name: forgeops-ciam-lab
description: CIAM lab for Ping Advanced Identity Software (ForgeRock AM/IDM) hands-on practice, SAML/SSO, non-human identities, Amazon Bedrock, ForgeOps minikube setup, and career prep. Use when working on identity labs, ForgeOps, SAML, AM federation, IDM, NHI, Bedrock, blog posts, or interview prep in this repo.
metadata:
  daily_time_budget_minutes: 30
  primary_focus: "SSO, SAML, Access Management (AM)"
  secondary_focus: "IDM, Non-Human Identities, Amazon Bedrock"
  forgeops_docs: "https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html"
  forgeops_start: "https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html"
  forgeops_repo: "https://github.com/ForgeRock/forgeops"
  forgeops_tag: "2026.2.1"
  # System specs — snapshot 2026-07-12T09:04:59+00:00 (collect-system-spec.sh to refresh)
  spec_snapshot_at: "2026-07-12T09:04:59+00:00"
  physical_host_os: "Windows"
  dev_environment: "Cursor cloud workspace (Docker container)"
  workspace_os: "Ubuntu 24.04.4 LTS"
  workspace_kernel: "6.12.94+"
  cpu_cores: "4"
  cpu_model: "Intel(R) Xeon(R) Processor"
  ram_total_gib: "15"
  ram_available_gib: "14"
  swap: "0B"
  disk_total_gib: "252"
  disk_free_gib: "220"
  virtualization: "docker"
  cgroup_type: "domain threaded"
  cgroup_subtree_control: "cpuset cpu pids"
  cgroup_memory_delegated: "false"
  docker_version: "29.6.1"
  docker_storage_driver: "vfs"
  node_version: "v22.14.0"
  python_version: "3.12.3"
  forgeops_runnable_in_workspace: "false"
  forgeops_deploy_target: "WSL2 Ubuntu + Docker Desktop (preferred on this laptop); Multipass only if Hyper-V driver works"
  local_repo_windows: "C:\\ciam"
  local_hostname: "LAPTOP-4GLJMDEF"
  wsl_distro: "Ubuntu"
  wsl_user: "jaya"
  wsl_repo_path: "/mnt/c/ciam"
  multipass_status: "installed but VirtualBox driver fails; prefer WSL2"
  forgeops_git_tag_live_docs: "2026.2.1"
  forgeops_git_tag_pdf_may_say: "2025.2.1 (stale — ignore)"
---

# ForgeOps CIAM Career Lab

## Practitioner context

- Role: CIAM engineer (ForgeRock IDM / AM experience)
- Daily time budget: **30 minutes** — every task must fit one focused session
- Learning priority: **SSO / SAML / AM** (hands-on), then IDM and non-human identities (NHI)
- Secondary skill: Amazon Bedrock (tie to NHI and automation use cases)

## System specs (your local — snapshot 2026-07-12T09:04:59+00:00)

| Property | Value |
|----------|-------|
| **Physical host** | Windows |
| **Dev environment** | Cursor cloud workspace (Docker container — NOT bare metal) |
| **Workspace OS** | Ubuntu 24.04.4 LTS, kernel 6.12.94+ |
| **CPU** | 4 cores — Intel(R) Xeon(R) Processor, x86_64 |
| **RAM** | 15 GiB total, 14 GiB available |
| **Swap** | 0B (none) |
| **Disk** | 252 GiB total, 220 GiB free |
| **Virtualization** | `docker` |
| **cgroup.type** | `domain threaded` |
| **cgroup.subtree_control** | `cpuset cpu pids` — **memory NOT delegated** |
| **Docker** | 29.6.1, storage driver `vfs` |
| **Node.js / Python** | v22.14.0 / 3.12.3 |
| **ForgeOps in workspace** | **false** — use Multipass VM or WSL2 on Windows |

### Deployment constraints (critical — do not ignore)

- **ForgeOps / minikube CANNOT run inside the Cursor workspace** due to `domain threaded` cgroup — memory limits blocked.
- **RAM is sufficient** (14 GiB free) — the blocker is cgroup, not hardware.
- **What works in Cursor workspace:** PostgreSQL (`start-postgresql.sh`), SAML SP app, docs, blog, code editing.
- **What needs Windows host:** Ping AM, IDM, PingDS — deploy via **WSL2 Ubuntu** (preferred) or Multipass.
- **Windows setup guide:** `docs/forgeops-windows-setup.md` and `LOCAL.md`
- **Cgroup diagnostic:** `./forgeops/scripts/check-cgroup.sh` (inside WSL)
- **Refresh specs:** `./forgeops/scripts/collect-system-spec.sh`

When user asks to "run ForgeOps" or "setup instance", **never** retry minikube in Cursor workspace unless `check-cgroup.sh` passes. Direct them to WSL2 on Windows instead.

## Windows host rules (physical_host_os = Windows)

Apply these whenever the user is on the Windows laptop (`LAPTOP-4GLJMDEF`, repo `C:\ciam`):

### Never confuse PowerShell with WSL

- Prompt `PS C:\...>` = **Windows PowerShell** — no `sed`, `chmod`, `/mnt/c/...`, or `./setup-forgerock.sh`.
- Prompt `jaya@LAPTOP-...:$` = **WSL Ubuntu** — run bash scripts here.
- If user pastes bash into PowerShell and gets `sed/chmod not recognized` or `C:\mnt\c\ciam` errors: tell them they are in the wrong shell.

### Preferred deploy path: WSL2 + Docker Desktop

1. Ensure Docker Desktop is **Running** (whale icon steady).
2. Open **Windows Terminal → Ubuntu**, or from PowerShell: `wsl -d Ubuntu`.
3. In Ubuntu:
   ```bash
   cd /mnt/c/ciam
   sed -i 's/\r$//' forgeops/scripts/*.sh forgeops/config/env.local
   chmod +x forgeops/scripts/*.sh
   ./forgeops/scripts/install-prerequisites-ubuntu.sh   # once
   ./forgeops/scripts/setup-forgerock.sh
   ```
4. Second Ubuntu window when prompted: `sudo minikube tunnel`
5. Windows hosts file: `127.0.0.1  forgeops.example.com`
6. Open: https://forgeops.example.com/platform

**PowerShell wrapper** (calls `setup-forgerock-in-wsl.sh` inside WSL). Do **not** embed bash in `@" "@` here-strings in `.ps1` files — Windows PowerShell 5.1 cannot parse them on LF files and errors with `Unexpected token 'Repo'`:

```powershell
cd C:\ciam
.\forgeops\scripts\setup-forgerock-wsl.ps1
```

If that parse error appears, skip the wrapper and use the Ubuntu commands above. A `=== DONE ===` banner right after the error does **not** mean AM/IDM is up.

### WSL timeout (`HCS_E_CONNECTION_TIMEOUT`)

```powershell
wsl --shutdown
# wait ~10s, ensure Docker Desktop is up
wsl -d Ubuntu
```

If still stuck: quit Docker Desktop fully, `wsl --shutdown`, restart Docker Desktop, then `wsl -d Ubuntu`.

### Forgotten WSL sudo password

From PowerShell (does not need old password):

```powershell
wsl -d Ubuntu -u root
passwd jaya
exit
```

### CRLF / env.local pitfalls

- `env.local: line N: $'\r': command not found` → Windows CRLF. Fix: `sed -i 's/\r$//' forgeops/config/env.local forgeops/scripts/*.sh`
- Never put bash in PowerShell `@" "@` here-strings. Windows PowerShell 5.1 cannot parse them on LF-ended `.ps1` files (`Unexpected token 'Repo'`). Call `setup-forgerock-in-wsl.sh` instead.
- `env.local` must be **bash-safe** (use `forgeops/config/env.example` shape with `export ...`). Do **not** put `C:\ciam` Windows paths in a file sourced by bash.
- `setup-forgerock.sh` sources env via `source <(sed 's/\r$//' ...)` to tolerate CRLF.
- `init-local-windows.ps1` copies `env.example` → `env.local` (not the Windows-only template).

### Git tag: PDF vs live docs

- Live Ping docs ([repositories](https://docs.pingidentity.com/forgeops/2025.2/start/repositories.html), [quick start](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)): tag **`2026.2.1`**
- Older PDF `forgeops-2025.2.pdf` may say `2025.2.1` and old paths (`cluster/resources`) — **follow live docs / `2026.2.1`**
- Clone: `https://github.com/ForgeRock/forgeops` — `forgeops-extras` is Terraform samples only, not needed for minikube.

### Multipass (fallback only)

- Binary: `C:\Program Files\Multipass\bin\multipass.exe` (often missing from PATH).
- Script: `forgeops/scripts/windows-forgerock.ps1` (uses full path to multipass).
- On this laptop Multipass `local.driver` was **virtualbox** and launch failed (`Could not generate a new UUID`). Prefer WSL2. To retry Multipass later: Hyper-V driver (`multipass set local.driver=hyperv`) after enabling Hyper-V.

### Agent behavior on Windows

1. Detect shell: if user shows `PS C:\`, give PowerShell/`wsl` commands — never raw bash.
2. Prefer WSL2 path over Multipass unless user insists or WSL cgroup check fails.
3. Keep `LOCAL.md` and `docs/forgeops-windows-setup.md` aligned with these rules.
4. Do not store or commit real passwords; if resetting WSL password, have the user run `passwd` themselves when possible.

## Non-negotiable rules for the agent

1. **Do not hallucinate ForgeRock/Ping steps.** Use only official documentation URLs cited in this repo (`docs/forgeops-setup.md`, Ping docs links). If unsure, say so and link to docs.
2. **Keep sessions to 30 minutes.** Each lab README must state: objective, prerequisites, steps, verification, and "stop here" point.
3. **Prefer hands-on over theory.** Every concept should map to a runnable app, script, or AM console task in this repo.
4. **Blog-ready output.** After completing a lab milestone, offer a draft section for `blog/drafts/` using the user's real experience tone (practitioner, not marketing).
5. **Career alignment.** Tie completed work to resume bullets and interview stories for remote CIAM roles (SAML federation, AM journeys, IDM workflows, NHI/service accounts, cloud identity).

## Repository map

| Path | Purpose |
|------|---------|
| `docs/forgeops-full-stack-setup.md` | Full stack: AM, IDM, DS-idrepo, DS-cts, optional Gateway |
| `docs/forgeops-setup.md` | Minikube quick reference (links to full stack) |
| `docs/30-min-daily-curriculum.md` | 12-week daily plan |
| `docs/career-roadmap-remote.md` | Job search, resume, and interview prep |
| `docs/saml-lab-am-as-idp.md` | AM as SAML IdP + sample SP app |
| `docs/nhi-lab-guide.md` | Non-human identity patterns with IDM/AM |
| `docs/postgresql-lab-setup.md` | Separate PostgreSQL app database |
| `docs/forgeops-windows-setup.md` | Windows WSL2 (preferred) / Multipass ForgeOps deploy |
| `LOCAL.md` | Short Windows cheat sheet for this laptop |
| `forgeops/scripts/setup-forgerock.sh` | Main ForgeOps minikube deploy (run in WSL/Linux) |
| `forgeops/scripts/setup-forgerock-in-wsl.sh` | WSL entrypoint called by the PowerShell wrapper |
| `forgeops/scripts/setup-forgerock-wsl.ps1` | PowerShell → WSL wrapper (no bash here-strings) |
| `forgeops/scripts/windows-forgerock.ps1` | Multipass fallback launcher |
| `forgeops/scripts/init-local-windows.ps1` | Creates bash-safe env.local + local-path.txt |
| `docs/forgeops-cloud-vm.md` | Cloud VM alternative when workspace is containerized |
| `infra/postgresql/` | Docker Compose PostgreSQL + schema |
| `forgeops/scripts/check-cgroup.sh` | Diagnose cgroup/memory block before deploy |
| `forgeops/scripts/collect-system-spec.sh` | Refresh system specs for skill metadata |
| `forgeops/scripts/start-postgresql.sh` | Start PostgreSQL |
| `forgeops/scripts/deploy-full-stack.sh` | One-shot AM + IDM + DS deploy |
| `forgeops/scripts/verify-stack.sh` | Check all platform pods |
| `forgeops/scripts/deploy-ping-gateway.sh` | Optional PingGateway (IG) |
| `apps/saml-service-provider/` | Node.js SAML SP for federation practice |
| `apps/oauth2-oidc-client/` | OIDC client for SSO comparison |
| `apps/bedrock-nhi-assistant/` | Bedrock demo for NHI-aware automation |
| `labs/week-*/` | Weekly hands-on exercises |
| `blog/drafts/` | Blog post drafts for public contribution |

## ForgeOps local setup (summary)

Official guides:
- [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html)
- [Quick deployment on minikube](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)

**Default stack (identity-platform chart):** AM, IDM, PingDS-idrepo, PingDS-cts, UIs.  
**PingGateway:** optional — not in default deploy. Use `deploy-ping-gateway.sh`.  
**Database:** PingDS (LDAP) = identity store. **PostgreSQL** (optional, `infra/postgresql/`) = separate app database — do not confuse the two.

1. Clone `https://github.com/ForgeRock/forgeops` and checkout tag `2026.2.1`
2. Install Docker, minikube, kubectl, helm, kubens, python3
3. Start minikube: 3 CPU, 9G RAM, 40G disk, ingress addon
4. Add hosts entry: `127.0.0.1 forgeops.example.com`
5. Python venv + `./bin/forgeops configure`
6. Apply self-signed issuer, run `./forgeops env`, create namespace, `./forgeops prereqs`
7. Run `sudo minikube tunnel` in a separate terminal
8. Helm install identity-platform
9. Login at `https://forgeops.example.com/platform` as `amadmin`

Full commands: `docs/forgeops-setup.md` and `forgeops/scripts/setup-minikube.sh`

## SAML / SSO lab pattern (AM as IdP)

When user asks for SAML hands-on:

1. Ensure ForgeOps AM is running
2. In AM admin UI: create **hosted IdP**, import **remote SP** metadata from `apps/saml-service-provider/metadata/`
3. Create a **Circle of Trust** linking IdP + SP
4. Start the SAML SP app locally; trigger login; verify assertion at SP
5. Document: Entity ID, ACS URL, NameID format, signing cert export

Official AM SAML reference:
- https://docs.pingidentity.com/pingoneaic/am-saml2/saml2-providers-and-cots.html
- https://docs.pingidentity.com/pingoneaic/am-saml2/saml2-reference.html

## Non-human identities (NHI) lab pattern

Focus areas (no fabricated product features):

- Service accounts vs human users in IDM
- OAuth2 client credentials / mTLS for machine clients
- Certificate-based auth for workloads
- Bedrock IAM roles vs application service principals (AWS side)
- Mapping NHI lifecycle: provision, rotate credentials, deprovision

Use `docs/nhi-lab-guide.md` and `apps/bedrock-nhi-assistant/` for exercises.

## Amazon Bedrock integration scope

Keep Bedrock labs **adjacent to CIAM**, not generic AI:

- Use Bedrock to summarize SAML metadata or debug federation errors (with redacted samples)
- Demonstrate least-privilege IAM for a workload calling Bedrock
- Show how NHI credentials should not be long-lived where rotation is possible

Do not claim ForgeRock has native Bedrock connectors unless documented.

## 30-minute session template

When planning a session, output:

```markdown
## Session: [title] (~30 min)
- Prerequisite: ...
- Minutes 0-5: ...
- Minutes 5-20: ...
- Minutes 20-28: ...
- Minutes 28-30: Write one resume bullet + one blog sentence
- Verify: ...
- Next session: ...
```

## Blog contribution workflow

1. Complete a lab in `labs/week-XX/`
2. Draft post in `blog/drafts/` with: problem, setup, steps, screenshots placeholders, pitfalls, references
3. Suggested platforms: Dev.to, Medium, LinkedIn article, or Ping/ForgeRock community (follow their contribution guidelines)
4. Cross-link to official Ping docs — never copy proprietary employer internals

## Career targeting (remote CIAM)

Highlight demonstrable outcomes from this repo:

- Deployed ForgeOps on minikube; configured SAML federation with sample SP
- Authored public blog posts on SAML debugging / AM federation
- Built NHI lab with credential rotation narrative
- AWS Bedrock integration with IAM least privilege

Target role titles: CIAM Engineer, IAM Engineer (ForgeRock/Ping), Access Management Consultant, Identity Platform Engineer

See `docs/career-roadmap-remote.md` for job boards, resume template, and interview prep.

## How to invoke

- Type `/forgeops-ciam-lab` for full context
- Or ask: "What is today's 30-minute lab?" / "Help me configure SAML with my SP app" / "Draft blog post for week 2"
