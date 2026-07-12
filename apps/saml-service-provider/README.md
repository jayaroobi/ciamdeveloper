# SAML Service Provider (hands-on lab)

Minimal Node.js SAML SP for federation practice with Ping Advanced Identity Software (ForgeOps AM).

## Quick start

```bash
npm install
cp .env.example .env
npm run generate-metadata
npm start
```

## AM configuration

See [docs/saml-lab-am-as-idp.md](../../docs/saml-lab-am-as-idp.md).

1. Import `metadata/sp-metadata.xml` as **Remote SP** in AM
2. Create **Hosted IdP** + **Circle of Trust**
3. Export IdP metadata to `metadata/idp-metadata.xml`
4. Restart this app and test SSO at http://localhost:3000

## Files

| File | Purpose |
|------|---------|
| `metadata/sp-metadata.xml` | Give to AM when creating remote SP |
| `metadata/idp-metadata.xml` | Export from AM (you create this) |
| `server.js` | SP login + ACS handler |
