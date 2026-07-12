/**
 * Optional PostgreSQL audit logging for SAML SP.
 * Set DATABASE_URL in .env — see docs/postgresql-lab-setup.md
 */
let pool = null;

async function getPool() {
  if (pool) return pool;
  const url = process.env.DATABASE_URL;
  if (!url) return null;

  const { Pool } = require('pg');
  pool = new Pool({ connectionString: url });
  await pool.query('SELECT 1');
  console.log('PostgreSQL connected for login audit');
  return pool;
}

async function recordSamlLogin({ nameID, email, ip, userAgent }) {
  const db = await getPool();
  if (!db) return;

  await db.query(
    `INSERT INTO app_users (external_id, email, display_name)
     VALUES ($1, $2, $3)
     ON CONFLICT (external_id) DO UPDATE SET
       email = COALESCE(EXCLUDED.email, app_users.email),
       updated_at = NOW()`,
    [nameID, email || null, email || nameID]
  );

  await db.query(
    `INSERT INTO login_audit (external_id, auth_method, ip_address, user_agent)
     VALUES ($1, 'saml', $2::inet, $3)`,
    [nameID, ip || null, userAgent || null]
  );
}

module.exports = { recordSamlLogin, getPool };
