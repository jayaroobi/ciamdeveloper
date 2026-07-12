# Week 1 — Deploy ForgeOps full stack

**Time:** ~30 min/day × 7 days  
**Outcome:** AM + IDM + DS running locally

## Day 1 — Prerequisites

```bash
./forgeops/scripts/install-prerequisites-ubuntu.sh
newgrp docker   # or re-login
docker run hello-world
```

**Verify:** all tools print versions.

## Day 2 — Deploy

```bash
cp forgeops/config/env.example forgeops/config/env.local
./forgeops/scripts/add-hosts-entry.sh
./forgeops/scripts/deploy-full-stack.sh
```

**Verify:** `kubectl get pods -n my-namespace`

## Day 3 — Login + explore

1. `./forgeops info | grep amadmin` (from forgeops/bin)
2. Open https://forgeops.example.com/platform
3. Open https://forgeops.example.com/am
4. Open https://forgeops.example.com/admin

**Verify:** all three UIs load.

## Day 4 — Understand DS

```bash
kubectl get statefulsets -n my-namespace
kubectl describe pod ds-idrepo-0 -n my-namespace | head -30
```

**Learn:** idrepo = identity DB, cts = token store.

## Day 5 — Run verify script

```bash
./forgeops/scripts/verify-stack.sh
```

**Resume bullet:** Deployed Ping AM/IDM/DS via ForgeOps on minikube.

## Day 6 (optional) — PingGateway

```bash
./forgeops/scripts/deploy-ping-gateway.sh
```

## Day 7 — Blog

Edit and publish `blog/drafts/01-forgeops-home-lab.md`.

**Next week:** `labs/week-02-saml-sso/` (create when starting SAML)
