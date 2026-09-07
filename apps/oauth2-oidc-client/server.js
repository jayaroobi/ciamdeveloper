require('dotenv').config();
const express = require('express');
const session = require('express-session');
const { Issuer, generators } = require('openid-client');

const PORT = process.env.PORT || 3001;
const issuerUrl = process.env.OIDC_ISSUER;
const clientId = process.env.OIDC_CLIENT_ID;
const clientSecret = process.env.OIDC_CLIENT_SECRET;
const redirectUri = process.env.OIDC_REDIRECT_URI || `http://localhost:${PORT}/callback`;

let client;

async function initOidc() {
  const issuer = await Issuer.discover(issuerUrl);
  client = new issuer.Client({
    client_id: clientId,
    client_secret: clientSecret,
    redirect_uris: [redirectUri],
    response_types: ['code'],
  });
}

const app = express();
app.use(
  session({
    secret: process.env.SESSION_SECRET || 'oidc-lab-secret',
    resave: false,
    saveUninitialized: false,
  })
);

app.get('/', (req, res) => {
  if (req.session.tokens) {
    res.send(`
      <h1>OIDC — authenticated</h1>
      <pre>${JSON.stringify(req.session.tokens, null, 2)}</pre>
      <p><a href="/logout">Logout</a></p>
    `);
    return;
  }
  res.send(`
    <h1>CIAM Lab — OIDC Client</h1>
    <p>Compare this browser flow with SAML in apps/saml-service-provider.</p>
    <p><a href="/login">Login with OIDC</a></p>
  `);
});

app.get('/login', (req, res) => {
  const codeVerifier = generators.codeVerifier();
  const codeChallenge = generators.codeChallenge(codeVerifier);
  req.session.codeVerifier = codeVerifier;
  const url = client.authorizationUrl({
    scope: 'openid profile email',
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
  });
  res.redirect(url);
});

app.get('/callback', async (req, res) => {
  try {
    const params = client.callbackParams(req);
    const tokenSet = await client.callback(redirectUri, params, {
      code_verifier: req.session.codeVerifier,
    });
    req.session.tokens = {
      sub: tokenSet.claims().sub,
      email: tokenSet.claims().email,
      scope: tokenSet.scope,
    };
    res.redirect('/');
  } catch (err) {
    res.status(500).send(`OIDC error: ${err.message}`);
  }
});

app.get('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/'));
});

initOidc()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`OIDC client on http://localhost:${PORT}`);
      console.log(`Issuer: ${issuerUrl}`);
    });
  })
  .catch((err) => {
    console.error('Failed to discover OIDC issuer:', err.message);
    console.error('Configure .env after creating OAuth2 client in AM');
    process.exit(1);
  });
