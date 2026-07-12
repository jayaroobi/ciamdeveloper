# Non-Human Identities (NHI) lab guide

NHI covers identities used by applications, services, APIs, and automation — not people logging in via browser SSO.

This lab stays within documented identity patterns. It does **not** invent proprietary ForgeRock features.

## Learning objectives

1. Distinguish human vs non-human identity lifecycle
2. Provision a service account in IDM (conceptual workflow)
3. Protect machine-to-machine access (OAuth2 client credentials, certificates)
4. Connect NHI thinking to AWS IAM + Bedrock (`apps/bedrock-nhi-assistant`)

## Week 3+ sessions (30 min each)

### Session 1 — NHI taxonomy

| Identity type | Auth pattern | Typical store |
|---------------|--------------|---------------|
| Human user | SSO / SAML / OIDC browser | IDM + AM |
| Service account | Client credentials, API key | IDM managed object |
| Workload / pod | mTLS, SPIFFE, IAM role | Cloud IAM |
| CI/CD pipeline | OIDC federation to cloud | GitHub Actions → AWS |

**Exercise:** List 5 NHIs in a typical Experian-style CIAM estate (do not use real names). Classify each.

### Session 2 — IDM managed object for service account

In ForgeOps IDM admin (when deployed):

1. Explore **Managed Objects → User** vs custom `ServiceAccount` object (if configured)
2. Document fields: `clientId`, `owner`, `rotationDate`, `scopes`
3. Create a provisioning workflow sketch (JSON mapping file in `labs/week-03-nhi/`)

Official IDM docs: https://docs.pingidentity.com/idm/

### Session 3 — AM OAuth2 client (machine client)

1. In AM: **Realms → alpha → Applications → OAuth 2.0 → Clients**
2. Create confidential client with **Client Credentials** grant
3. Obtain access token via REST
4. Call a protected resource

This is the AM-side NHI pattern most employers ask about.

### Session 4 — Bedrock + least privilege

```bash
cd apps/bedrock-nhi-assistant
cp .env.example .env
# Set AWS_REGION, model ID; use IAM role or short-lived credentials
pip install -r requirements.txt
python main.py --prompt "Summarize SAML ACS troubleshooting steps"
```

**Principle:** The Bedrock caller should be an IAM role assumed by a workload — not a long-lived access key in source code.

## NHI interview talking points

- Rotation: how you expire and re-provision service credentials
- Ownership: every NHI has a human owner and a business justification
- Blast radius: scope OAuth clients narrowly; prefer certificate-bound identities
- Audit: correlate NHI auth events in AM access logs

## References

- Ping AM OAuth 2.0: https://docs.pingidentity.com/pingoneaic/am-oauth2/
- AWS Bedrock IAM: https://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html
