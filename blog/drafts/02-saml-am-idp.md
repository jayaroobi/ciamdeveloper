# SAML Federation with Ping AM as IdP — Home Lab Walkthrough

*Draft — fill in after completing Week 2 lab.*

## Problem

Enterprise apps need SSO. SAML 2.0 is still the standard for B2B and many internal apps. I wanted hands-on practice beyond production access — configuring metadata, Circle of Trust, and ACS validation myself.

## Architecture

```text
Browser → Node.js SP (localhost:3000)
       → Ping AM IdP (forgeops.example.com)
       → SAML Response POST → /saml/acs
       → PostgreSQL login_audit
```

## What I configured

1. **Hosted IdP** in AM (alpha realm)
2. **Remote SP** from generated `sp-metadata.xml`
3. **Circle of Trust** linking both
4. Optional: login events in PostgreSQL

## Key settings

| Setting | My value |
|---------|----------|
| SP Entity ID | `urn:ciam-lab:saml-sp` |
| ACS URL | `http://localhost:3000/saml/acs` |
| IdP Entity ID | `urn:ciam-lab:am-idp` |
| CoT name | `ciam-lab-cot` |

## Steps (summary)

<!-- Add your screenshots and exact clicks here after lab -->

1. Import SP metadata in AM
2. Create hosted IdP
3. Create CoT
4. Export IdP metadata to SP app
5. Test login

## Pitfall I hit

<!-- e.g. forgot CoT, wrong ACS URL, stale IdP cert -->

## Verification

```sql
SELECT * FROM login_audit WHERE auth_method = 'saml' ORDER BY logged_in_at DESC LIMIT 5;
```

## References

- [Ping AM SAML providers and CoTs](https://docs.pingidentity.com/pingoneaic/am-saml2/saml2-providers-and-cots.html)
- [Lab repo SAML guide](https://github.com/jayaroobi/ciamdeveloper/blob/main/docs/saml-lab-am-as-idp.md)

---

*Tags: #saml #sso #pingidentity #forgerock #ciam*
