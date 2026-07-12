# CIAM Developer Lab

Hands-on lab for Ping Advanced Identity Software (ForgeRock AM/IDM) — SAML/SSO, ForgeOps, non-human identities, and Amazon Bedrock.

**Goal:** Remote CIAM role ~60L INR from Sohar, Oman (currently ~36L).

## Quick start — local ForgeOps (AM + IDM + DS)

Run on your **local machine** (Docker + minikube required):

```bash
# 1. Prerequisites
./forgeops/scripts/install-prerequisites-ubuntu.sh

# 2. Configure
cp forgeops/config/env.example forgeops/config/env.local

# 3. Deploy full stack
./forgeops/scripts/deploy-full-stack.sh
# Terminal 2: sudo minikube tunnel

# 4. Verify
./forgeops/scripts/verify-stack.sh
```

Open **https://forgeops.example.com/platform** — password from `./forgeops info | grep amadmin`.

Full guide: [docs/forgeops-full-stack-setup.md](docs/forgeops-full-stack-setup.md)

Official docs:
- [Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html)
- [Quick deployment on minikube](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)

## What's in this repo

| Path | Description |
|------|-------------|
| [docs/forgeops-full-stack-setup.md](docs/forgeops-full-stack-setup.md) | AM, IDM, DS, optional Gateway |
| [docs/saml-lab-am-as-idp.md](docs/saml-lab-am-as-idp.md) | SAML SSO hands-on |
| [docs/30-min-daily-curriculum.md](docs/30-min-daily-curriculum.md) | 12-week learning plan |
| [docs/career-roadmap-60l-remote.md](docs/career-roadmap-60l-remote.md) | Job search guide |
| [apps/saml-service-provider/](apps/saml-service-provider/) | Node.js SAML SP |
| [apps/oauth2-oidc-client/](apps/oauth2-oidc-client/) | OIDC comparison app |
| [apps/bedrock-nhi-assistant/](apps/bedrock-nhi-assistant/) | Bedrock + NHI demo |
| [.cursor/skills/forgeops-ciam-lab/](.cursor/skills/forgeops-ciam-lab/) | Cursor Agent skill |

## Cursor skill

Type `/forgeops-ciam-lab` in Agent chat or ask: *"What is today's 30-minute lab?"*

## Daily time budget

**30 minutes/day** — see curriculum for structured sessions.

## Stack components

| Component | Default deploy? | Notes |
|-----------|-----------------|-------|
| PingAM | Yes | SSO, SAML, OAuth2 |
| PingIDM | Yes | Provisioning |
| PingDS (idrepo + cts) | Yes | Identity directory (LDAP) |
| PostgreSQL | Optional | Separate app DB — `infra/postgresql/` |
| PingGateway | Optional | `deploy-ping-gateway.sh` |

PostgreSQL guide: [docs/postgresql-lab-setup.md](docs/postgresql-lab-setup.md)

## License

Lab scripts and apps: use freely. ForgeOps/Ping Docker images require [Ping license terms](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html).
