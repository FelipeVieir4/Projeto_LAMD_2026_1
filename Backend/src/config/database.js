import { Pool } from 'pg';

function toNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function toBoolean(value, fallback) {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }

  return String(value).trim().toLowerCase() !== 'false';
}

const sslEnabled = toBoolean(process.env.DB_SSL, true);

const sslConfig = sslEnabled
  ? {
    rejectUnauthorized: false
  }
  : false;

const hasDatabaseUrl = Boolean(String(process.env.DATABASE_URL ?? '').trim());

const pool = hasDatabaseUrl
  ? new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: sslConfig
  })
  : new Pool({
    host: process.env.DB_HOST,
    port: toNumber(process.env.DB_PORT, 5432),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl: sslConfig
  });

export async function query(sql, params = []) {
  return pool.query(sql, params);
}

export async function checkDatabaseConnection() {
  const result = await query('SELECT 1 AS ok');
  return result.rows[0]?.ok === 1;
}

export { pool };
