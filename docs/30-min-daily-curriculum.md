# 30-minute daily curriculum (12 weeks)

Goal: hands-on Ping / ForgeRock CIAM skills (SSO, SAML, AM, IDM) with a public lab portfolio.

**Daily budget:** 30 minutes. Do not skip verification steps.

## Week 1 — ForgeOps local stack

| Day | Session | Doc |
|-----|---------|-----|
| Mon | Install prerequisites | `forgeops/scripts/install-prerequisites-ubuntu.sh` |
| Tue | Deploy identity-platform (AM+IDM+DS) | `docs/forgeops-full-stack-setup.md` |
| Wed | Verify pods + login to `/platform` | `forgeops/scripts/verify-stack.sh` |
| Thu | Explore AM console `/am` — realms, services | Official AM docs |
| Fri | Explore IDM `/admin` — managed objects | Official IDM docs |
| Sat | Optional: deploy PingGateway | `forgeops/scripts/deploy-ping-gateway.sh` |
| Sun | Blog draft: "My ForgeOps home lab" | `blog/drafts/01-forgeops-home-lab.md` |

## Week 2 — SAML / SSO (primary focus)

| Day | Session | Doc |
|-----|---------|-----|
| Mon | Read SAML CoT concepts | `docs/saml-lab-am-as-idp.md` |
| Tue | Generate SP metadata, import to AM | `apps/saml-service-provider/` |
| Wed | Create hosted IdP + CoT | AM admin UI |
| Thu | Test SSO end-to-end | SP app localhost:3000 |
| Fri | Debug one failure (signature/ACS) | Troubleshooting table in SAML doc |
| Sat | Compare OIDC client app | `apps/oauth2-oidc-client/` |
| Sun | Blog: SAML federation walkthrough | `blog/drafts/02-saml-am-idp.md` |

## Week 3 — IDM provisioning basics

| Day | Session |
|-----|---------|
| Mon | IDM managed objects overview |
| Tue | Create test user via REST |
| Wed | Reconciliation concept (read-only) |
| Thu | Mapping script basics |
| Fri | Connect IDM user to AM login |
| Sat | NHI taxonomy | `docs/nhi-lab-guide.md` |
| Sun | Resume bullet + LinkedIn post |

## Week 4 — AM journeys + OAuth2

| Day | Session |
|-----|---------|
| Mon | Authentication tree/journey UI |
| Tue | Create OAuth2 confidential client |
| Wed | Client credentials grant (NHI pattern) |
| Thu | Token introspection |
| Fri | Policy / resource server basics |
| Sat | Bedrock lab | `apps/bedrock-nhi-assistant/` |
| Sun | Blog: OAuth2 vs SAML when to use |

## Weeks 5–8 — Depth + contribution

- Week 5: SAML attribute mapping + NameID formats
- Week 6: Single Logout (SLO)
- Week 7: IDM workflow + service account object design
- Week 8: PingGateway reverse proxy lab (if IG deployed)

Each week: 5 hands-on days + 1 blog/contribution day + 1 review day.

## Weeks 9–12 — Job search sprint

| Week | Focus |
|------|-------|
| 9 | Resume rewrite with lab projects |
| 10 | Apply 5 remote roles/week (see career doc) |
| 11 | Mock interviews — SAML deep dive |
| 12 | Portfolio: GitHub repo public + 3 blog posts |

## Session template

Every day, the agent should produce:

1. **Objective** (one sentence)
2. **Steps** (timed to 30 min)
3. **Verify** (command or UI check)
4. **Resume bullet** (one line)
5. **Next** (tomorrow's session)

## Invoke in Cursor

```
/forgeops-ciam-lab What is today's 30-minute lab?
```
