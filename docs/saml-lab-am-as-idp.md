# SAML lab: Ping AM as IdP + local Service Provider

> **Official AM SAML docs:**
> - [Set up IdPs, SPs, and CoTs](https://docs.pingidentity.com/pingoneaic/am-saml2/saml2-providers-and-cots.html)
> - [SAML 2.0 reference](https://docs.pingidentity.com/pingoneaic/am-saml2/saml2-reference.html)

## Goal (~30 min)

Authenticate to the sample Node.js app (`apps/saml-service-provider`) via SAML SSO where **AM is the IdP**.

## Architecture

```text
Browser → SAML SP (localhost:3000) → AM IdP (forgeops.example.com) → login → SAML Response → SP
```

## Prerequisites

- ForgeOps AM running ([forgeops-setup.md](forgeops-setup.md))
- At least one test user in the `alpha` realm (or your chosen realm)

## Part A — Start the SAML SP (5 min)

```bash
cd apps/saml-service-provider
cp .env.example .env
npm install
npm run generate-metadata   # creates metadata/sp-metadata.xml
npm start
```

Default SP URLs:

| Setting | Value |
|---------|-------|
| Entity ID | `urn:ciam-lab:saml-sp` |
| ACS URL | `http://localhost:3000/saml/acs` |
| SP metadata | `metadata/sp-metadata.xml` |

## Part B — Configure AM (15 min)

In AM admin UI (`https://forgeops.example.com/platform`):

### 1. Create hosted IdP

1. Go to **Realms → alpha → Dashboard → SAML Applications**
2. **Add Entity Provider → Hosted**
3. Set Entity ID (e.g. `urn:ciam-lab:am-idp`)
4. Set **Identity Provider Meta Alias** (URL-friendly, no slashes), e.g. `ciam-idp`
5. Save

### 2. Import remote SP

1. **Add Entity Provider → Remote**
2. Upload `apps/saml-service-provider/metadata/sp-metadata.xml`
3. Leave Update Type as `CREATE`
4. Save

### 3. Create Circle of Trust (CoT)

1. **Applications → Federation → Circles of Trust → Add**
2. Name: `ciam-lab-cot`
3. Select your hosted **IdP** and remote **SP**
4. Save

### 4. Export IdP metadata (for SP config)

From the hosted IdP, export standard metadata XML. Save as:

```text
apps/saml-service-provider/metadata/idp-metadata.xml
```

Update `.env`:

```bash
IDP_METADATA_PATH=./metadata/idp-metadata.xml
```

Restart the SP: `npm start`

## Part C — Test SSO (8 min)

1. Open http://localhost:3000
2. Click **Login with SAML**
3. You should redirect to AM login
4. Authenticate as a test user
5. Verify the SP shows NameID and attributes

### Verification checklist

- [ ] SAML AuthnRequest leaves SP
- [ ] AM login page appears
- [ ] POST to `/saml/acs` succeeds (no signature error)
- [ ] SP session shows authenticated user

## Part D — Resume bullet + blog note (2 min)

**Resume bullet example:**

> Configured SAML 2.0 federation between Ping Advanced Identity Software (AM) and a Node.js service provider using Circle of Trust, metadata exchange, and ACS validation.

## Common pitfalls

| Symptom | Likely cause |
|---------|----------------|
| Signature validation failed | IdP cert in SP config outdated; re-export metadata |
| No redirect to AM | CoT missing IdP or SP |
| ACS 404 | ACS URL mismatch between SP metadata and AM remote SP config |
| Cookie/session lost | SP `callbackUrl` must match registered ACS |

## Next session

- Add Single Logout (SLO)
- Compare with OIDC flow in `apps/oauth2-oidc-client`
- Week 2 lab: `labs/week-02-saml-sso/`
