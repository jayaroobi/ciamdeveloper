# OIDC Relying Party (comparison lab)

Use this app **after** SAML week to compare federation models side by side.

## AM setup (summary)

1. AM → Realms → alpha → Applications → OAuth 2.0 → Clients → Create
2. Client ID: `ciam-lab-oidc`
3. Grant types: Authorization Code
4. Redirect URI: `http://localhost:3001/callback`
5. Scopes: `openid`, `profile`, `email`

## Run

```bash
npm install
cp .env.example .env
# Edit OIDC_CLIENT_SECRET from AM
npm start
```

Open http://localhost:3001

## Learning point

| SAML | OIDC |
|------|------|
| XML metadata exchange | Discovery document + JSON |
| POST binding to ACS | Redirect + code exchange |
| Common in enterprise B2B | Common in modern SaaS |

Both are configured in AM; knowing both strengthens CIAM interview answers.
