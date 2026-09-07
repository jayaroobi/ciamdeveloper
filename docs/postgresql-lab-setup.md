# PostgreSQL in the CIAM lab

Separate **PostgreSQL** for application data — alongside ForgeOps (PingDS remains the identity directory).

## Architecture

```text
┌─────────────────────────────────────────────────────────┐
│  ForgeOps (minikube)                                    │
│  PingAM / PingIDM  ──►  PingDS idrepo  (identity LDAP)  │
│                      ──►  PingDS cts     (tokens)       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Docker Compose (host)                                  │
│  PostgreSQL  ──►  app_users, login_audit, service_accts │
└─────────────────────────────────────────────────────────┘
         ▲
         │ DATABASE_URL
   SAML SP / custom apps (localhost)
```

| Store | Technology | Purpose |
|-------|------------|---------|
| Identity repo | **PingDS** (`ds-idrepo`) | Users, groups, AM/IDM config — managed by ForgeOps |
| Token store | **PingDS** (`ds-cts`) | OAuth/SAML sessions |
| **App database** | **PostgreSQL** (this lab) | Business data, audit logs, NHI registry metadata |

> Do **not** replace PingDS with PostgreSQL for ForgeOps identity storage in this lab. That would require custom IDM JDBC repository configuration outside the default ForgeOps chart. PostgreSQL here models how real apps keep **their own data** while users authenticate via AM.

## Local path

```text
~/ciamdeveloper/infra/postgresql/
├── docker-compose.yml
├── .env.example
└── init/01-ciam-lab-schema.sql
```

## Quick start (~5 min)

```bash
# From repo root
./forgeops/scripts/start-postgresql.sh
./forgeops/scripts/verify-postgresql.sh
```

## Connection details (defaults)

| Setting | Value |
|---------|-------|
| Host | `localhost` |
| Port | `5432` |
| Database | `ciam_lab` |
| User | `ciam_app` |
| Password | `ciam_lab_dev` |

Connection string:

```text
postgresql://ciam_app:ciam_lab_dev@localhost:5432/ciam_lab
```

Copy env for apps:

```bash
cp infra/postgresql/.env.example infra/postgresql/.env
```

## Optional pgAdmin UI

```bash
cd infra/postgresql
docker compose --profile admin up -d
```

Open http://localhost:5050  
Login: `admin@ciam-lab.local` / `ciam_lab_dev`

Add server: host `postgresql`, port `5432`, user `ciam_app`.

## psql CLI

```bash
psql "postgresql://ciam_app:ciam_lab_dev@localhost:5432/ciam_lab"
```

Install client if needed: `sudo apt install postgresql-client`

## Schema tables

| Table | Purpose |
|-------|---------|
| `app_users` | App profile linked to SAML NameID / OIDC `sub` |
| `login_audit` | SSO login events from sample apps |
| `service_accounts` | NHI registry (lab metadata) |

## Use with SAML SP app

The SAML service provider can write login audit rows when `DATABASE_URL` is set:

```bash
cd apps/saml-service-provider
echo 'DATABASE_URL=postgresql://ciam_app:ciam_lab_dev@localhost:5432/ciam_lab' >> .env
npm install
npm start
```

After SAML login, check:

```sql
SELECT * FROM login_audit ORDER BY logged_in_at DESC LIMIT 10;
```

## Stop / reset

```bash
./forgeops/scripts/stop-postgresql.sh

# Full reset (deletes data volume)
cd infra/postgresql && docker compose down -v
```

## Deploy order (recommended)

1. `./forgeops/scripts/start-postgresql.sh`
2. `./forgeops/scripts/deploy-full-stack.sh` (+ `minikube tunnel`)
3. `./forgeops/scripts/verify-postgresql.sh`
4. `./forgeops/scripts/verify-stack.sh`

## Interview talking point

*"PingDS holds authoritative identity data for AM/IDM. Line-of-business applications use their own PostgreSQL (or other RDBMS) for app data, linking records to the SSO subject from SAML/OIDC — separation of concerns between CIAM platform and application persistence."*
