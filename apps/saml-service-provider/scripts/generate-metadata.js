/**
 * Generate SP metadata XML for import into AM as Remote SP.
 * Run: npm run generate-metadata
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');

const entityId = process.env.SAML_ENTITY_ID || 'urn:ciam-lab:saml-sp';
const acsUrl = process.env.SAML_ACS_URL || 'http://localhost:3000/saml/acs';

const metadataDir = path.join(__dirname, '..', 'metadata');
if (!fs.existsSync(metadataDir)) {
  fs.mkdirSync(metadataDir, { recursive: true });
}

const metadata = `<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
  entityID="${entityId}">
  <SPSSODescriptor
    AuthnRequestsSigned="false"
    WantAssertionsSigned="true"
    protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <AssertionConsumerService
      Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
      Location="${acsUrl}"
      index="0"
      isDefault="true"/>
  </SPSSODescriptor>
</EntityDescriptor>
`;

const outPath = path.join(metadataDir, 'sp-metadata.xml');
fs.writeFileSync(outPath, metadata);
console.log(`Wrote ${outPath}`);
console.log('Import this file in AM: Add Entity Provider → Remote');
