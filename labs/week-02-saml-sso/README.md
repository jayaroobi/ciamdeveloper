# Week 2 — SAML SSO with AM as IdP

**Prerequisite:** Week 1 complete — ForgeOps AM running, PostgreSQL optional but recommended.

**Time:** ~30 min/day  
**Outcome:** Browser SSO from Node.js SP → Ping AM → SAML assertion → PostgreSQL audit

## Day 1 — Read + prepare (~30 min)

1. Read [docs/saml-lab-am-as-idp.md](../../docs/saml-lab-am-as-idp.md) (10 min)
2. Skim official doc: [Set up IdPs, SPs, and CoTs](https://docs.pingidentity.com/pingoneaic/am-saml2/saml2-providers-and-cots.html) (10 min)
3. Generate SP metadata:

```bash
cd ~/ciamdeveloper/apps/saml-service-provider
npm install
cp .env.example .env
npm run generate-metadata
```

4. Confirm file exists: `metadata/sp-metadata.xml`

**Verify:** metadata file has your Entity ID and ACS URL.

**Resume bullet prep:** *Understand SAML metadata exchange between IdP and SP.*

---

## Day 2 — Import remote SP in AM (~30 min)

1. AM console → **Realms → alpha → Dashboard → SAML Applications**
2. **Add Entity Provider → Remote**
3. Upload `~/ciamdeveloper/apps/saml-service-provider/metadata/sp-metadata.xml`
4. Update Type: `CREATE` → Save

**Verify:** Remote SP appears under Entity Providers.

---

## Day 3 — Hosted IdP + Circle of Trust (~30 min)

1. **Add Entity Provider → Hosted**
   - Entity ID: `urn:ciam-lab:am-idp`
   - IdP Meta Alias: `ciam-idp`
2. **Circles of Trust → Add** → name `ciam-lab-cot`
3. Add hosted IdP + remote SP to CoT
4. Export IdP metadata → save as:
   `apps/saml-service-provider/metadata/idp-metadata.xml`

**Verify:** CoT shows both IdP and SP.

---

## Day 4 — End-to-end SSO test (~30 min)

Terminal 1 — PostgreSQL (if not running):

```bash
~/ciamdeveloper/forgeops/scripts/start-postgresql.sh
```

Terminal 2 — SAML SP:

```bash
cd ~/ciamdeveloper/apps/saml-service-provider
echo 'DATABASE_URL=postgresql://ciam_app:ciam_lab_dev@localhost:5432/ciam_lab' >> .env
npm start
```

1. Open http://localhost:3000
2. Click **Login with SAML**
3. Authenticate at AM
4. Confirm SP shows NameID

**Verify:** No ACS signature error; user displayed on SP home page.

---

## Day 5 — PostgreSQL audit (~30 min)

```bash
psql "postgresql://ciam_app:ciam_lab_dev@localhost:5432/ciam_lab" \
  -c "SELECT external_id, auth_method, logged_in_at FROM login_audit ORDER BY 1 DESC LIMIT 5;"
```

**Verify:** Row with `auth_method = saml` after your login.

**Resume bullet:** *Configured SAML 2.0 federation between Ping AM and Node.js SP with Circle of Trust and login audit in PostgreSQL.*

---

## Day 6 — Compare OIDC (~30 min)

```bash
cd ~/ciamdeveloper/apps/oauth2-oidc-client
npm install && cp .env.example .env
# Create OAuth2 client in AM, set secret in .env
npm start
```

Open http://localhost:3001 — compare redirect flow vs SAML POST.

---

## Day 7 — Blog

Edit and publish `blog/drafts/02-saml-am-idp.md` (create from Day 4 notes).

---

## Troubleshooting quick reference

| Error | Fix |
|-------|-----|
| IdP metadata missing | Re-export from AM hosted IdP |
| Signature failed | Re-export IdP metadata; check cert in XML |
| No AM redirect | CoT missing IdP or SP |
| PG audit empty | Check DATABASE_URL; PostgreSQL must be running |
