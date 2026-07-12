---
name: forgeops-ciam-lab
description: CIAM career lab for Ping Advanced Identity Software (ForgeRock AM/IDM) hands-on practice, SAML/SSO, non-human identities, Amazon Bedrock, ForgeOps minikube setup, and remote job targeting (36L to 60L INR from Oman). Use when working on identity labs, ForgeOps, SAML, AM federation, IDM, NHI, Bedrock, blog posts, or career prep in this repo.
metadata:
  current_ctc_inr: "3600000"
  target_ctc_inr: "6000000"
  location: "Sohar, Oman (remote)"
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
  forgeops_deploy_target: "Windows Multipass VM or WSL2 (see docs/forgeops-windows-setup.md)"
---

# ForgeOps CIAM Career Lab

## Practitioner context

- Role: CIAM engineer (ForgeRock IDM / AM experience at Experian)
- Current compensation: ~36L INR per annum
- Goal: remote role at ~60L INR, working from Sohar, Oman
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
- **What needs Windows host VM:** Ping AM, IDM, PingDS — deploy via **Multipass VM** or **WSL2**.
- **Windows setup guide:** `docs/forgeops-windows-setup.md`
- **Cgroup diagnostic:** `./forgeops/scripts/check-cgroup.sh`
- **Refresh specs:** `./forgeops/scripts/collect-system-spec.sh`

When user asks to "run ForgeOps" or "setup instance", **never** retry minikube in Cursor workspace unless `check-cgroup.sh` passes. Direct them to Multipass/WSL2 on Windows instead.

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
| `docs/career-roadmap-60l-remote.md` | Job search, resume, and interview prep |
| `docs/saml-lab-am-as-idp.md` | AM as SAML IdP + sample SP app |
| `docs/nhi-lab-guide.md` | Non-human identity patterns with IDM/AM |
| `docs/postgresql-lab-setup.md` | Separate PostgreSQL app database |
| `docs/forgeops-windows-setup.md` | Windows Multipass VM / WSL2 ForgeOps deploy |
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
4. Cross-link to official Ping docs — never copy proprietary Experian internals

## Career targeting (60L remote)

Highlight demonstrable outcomes from this repo:

- Deployed ForgeOps on minikube; configured SAML federation with sample SP
- Authored public blog posts on SAML debugging / AM federation
- Built NHI lab with credential rotation narrative
- AWS Bedrock integration with IAM least privilege

Target role titles: CIAM Engineer, IAM Engineer (ForgeRock/Ping), Access Management Consultant, Identity Platform Engineer

See `docs/career-roadmap-60l-remote.md` for job boards, resume template, and interview prep.

## How to invoke

- Type `/forgeops-ciam-lab` for full context
- Or ask: "What is today's 30-minute lab?" / "Help me configure SAML with my SP app" / "Draft blog post for week 2"
