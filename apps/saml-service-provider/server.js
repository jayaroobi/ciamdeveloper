require('dotenv').config();
const fs = require('fs');
const path = require('path');
const express = require('express');
const session = require('express-session');
const { SAML } = require('@node-saml/node-saml');
const { recordSamlLogin } = require('./db');

const PORT = process.env.PORT || 3000;
const entityId = process.env.SAML_ENTITY_ID || 'urn:ciam-lab:saml-sp';
const callbackUrl = process.env.SAML_CALLBACK_URL || 'http://localhost:3000/saml/acs';
const idpMetadataPath = process.env.IDP_METADATA_PATH || './metadata/idp-metadata.xml';

function loadIdpCertFromMetadata(metadataPath) {
  if (!fs.existsSync(metadataPath)) {
    console.warn(`IdP metadata not found at ${metadataPath}. Export from AM first.`);
    return null;
  }
  const xml = fs.readFileSync(metadataPath, 'utf8');
  const match = xml.match(/<X509Certificate>([^<]+)<\/X509Certificate>/);
  if (!match) {
    throw new Error('No X509Certificate found in IdP metadata');
  }
  const b64 = match[1].replace(/\s/g, '');
  return `-----BEGIN CERTIFICATE-----\n${b64.match(/.{1,64}/g).join('\n')}\n-----END CERTIFICATE-----`;
}

function createSamlClient() {
  const cert = loadIdpCertFromMetadata(path.resolve(idpMetadataPath));
  if (!cert) {
    return null;
  }
  const idpIssuerMatch = fs
    .readFileSync(path.resolve(idpMetadataPath), 'utf8')
    .match(/entityID="([^"]+)"/);
  return new SAML({
    issuer: entityId,
    callbackUrl,
    idpCert: cert,
    identifierFormat: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
    wantAssertionsSigned: true,
    idpIssuer: idpIssuerMatch ? idpIssuerMatch[1] : undefined,
  });
}

const app = express();
app.use(express.urlencoded({ extended: false }));
app.use(
  session({
    secret: process.env.SESSION_SECRET || 'ciam-lab-dev-secret',
    resave: false,
    saveUninitialized: false,
  })
);

app.get('/', (req, res) => {
  if (req.session.user) {
    res.send(`
      <h1>SAML SP — authenticated</h1>
      <pre>${JSON.stringify(req.session.user, null, 2)}</pre>
      <p><a href="/logout">Logout</a></p>
    `);
    return;
  }
  res.send(`
    <h1>CIAM Lab — SAML Service Provider</h1>
    <p>AM acts as IdP. This app is the SP.</p>
    <p><a href="/login">Login with SAML</a></p>
    <p>Metadata: <a href="/metadata">/metadata</a></p>
  `);
});

app.get('/metadata', (req, res) => {
  const metaPath = path.join(__dirname, 'metadata', 'sp-metadata.xml');
  if (fs.existsSync(metaPath)) {
    res.type('application/xml').send(fs.readFileSync(metaPath, 'utf8'));
  } else {
    res.status(404).send('Run npm run generate-metadata first');
  }
});

app.get('/login', async (req, res) => {
  const saml = createSamlClient();
  if (!saml) {
    res.status(503).send(
      'IdP metadata missing. Export from AM and save to metadata/idp-metadata.xml'
    );
    return;
  }
  try {
    const url = await saml.getAuthorizeUrlAsync('', {}, {});
    res.redirect(url);
  } catch (err) {
    res.status(500).send(`SAML error: ${err.message}`);
  }
});

app.post('/saml/acs', async (req, res) => {
  const saml = createSamlClient();
  if (!saml) {
    res.status(503).send('IdP metadata missing');
    return;
  }
  try {
    const { profile } = await saml.validatePostResponseAsync(req.body);
    req.session.user = {
      nameID: profile.nameID,
      attributes: profile.attributes || {},
      sessionIndex: profile.sessionIndex,
    };
    recordSamlLogin({
      nameID: profile.nameID,
      email: profile.attributes?.email || profile.attributes?.mail,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    }).catch((err) => console.warn('PostgreSQL audit skip:', err.message));
    res.redirect('/');
  } catch (err) {
    res.status(401).send(`ACS validation failed: ${err.message}`);
  }
});

app.get('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/'));
});

app.listen(PORT, () => {
  console.log(`SAML SP listening on http://localhost:${PORT}`);
  console.log(`Entity ID: ${entityId}`);
});
