-- CIAM lab application database (NOT the identity store)
-- Identity data lives in PingDS (ds-idrepo) via ForgeOps.
-- PostgreSQL holds application/business data linked to SSO users by subject/nameid.

CREATE TABLE IF NOT EXISTS app_users (
  id            SERIAL PRIMARY KEY,
  external_id   VARCHAR(255) NOT NULL UNIQUE,  -- SAML NameID or OIDC sub
  email         VARCHAR(255),
  display_name  VARCHAR(255),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS login_audit (
  id            SERIAL PRIMARY KEY,
  external_id   VARCHAR(255) NOT NULL,
  auth_method   VARCHAR(50) NOT NULL,          -- saml, oidc, local
  ip_address    INET,
  user_agent    TEXT,
  logged_in_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS service_accounts (
  id            SERIAL PRIMARY KEY,
  client_id     VARCHAR(255) NOT NULL UNIQUE,
  owner_email   VARCHAR(255),
  purpose       TEXT,
  rotated_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_login_audit_external_id ON login_audit (external_id);
CREATE INDEX IF NOT EXISTS idx_login_audit_logged_in_at ON login_audit (logged_in_at DESC);

-- Sample row for connectivity tests
INSERT INTO service_accounts (client_id, owner_email, purpose)
VALUES ('lab-demo-client', 'you@example.com', 'NHI lab placeholder')
ON CONFLICT (client_id) DO NOTHING;
