import { pool, query } from '../../config/database.js';

const programAliases = new Map([
  ['customer', 'customer'],
  ['client', 'customer'],
  ['cliente', 'customer'],
  ['partner', 'partner'],
  ['parceiro', 'partner']
]);

export function normalizeProgram(program) {
  const normalized = String(program ?? '').trim().toLowerCase();
  return programAliases.get(normalized) ?? null;
}

function normalizeEmail(email) {
  return String(email ?? '').trim().toLowerCase();
}

function normalizeSpecialties(specialties) {
  if (!specialties) {
    return [];
  }

  if (Array.isArray(specialties)) {
    return specialties.map((specialty) => String(specialty).trim()).filter(Boolean);
  }

  return String(specialties)
    .split(',')
    .map((specialty) => specialty.trim())
    .filter(Boolean);
}

function mapCustomerRow(row) {
  return {
    id: row.id,
    program: 'customer',
    email: row.email,
    passwordHash: row.password_hash,
    name: row.name,
    phone: row.phone,
    status: row.status,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

function mapPartnerRow(row) {
  return {
    id: row.id,
    program: 'partner',
    email: row.email,
    passwordHash: row.password_hash,
    phone: row.phone,
    document: row.document,
    companyName: row.company_name,
    bio: row.bio,
    specialties: row.specialties ?? [],
    isActive: row.is_active,
    status: row.is_active ? 'active' : 'blocked',
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

export async function findUserByEmail(program, email) {
  const normalizedProgram = normalizeProgram(program);

  if (!normalizedProgram) {
    return null;
  }

  const normalizedEmail = normalizeEmail(email);

  if (normalizedProgram === 'customer') {
    const result = await query(
      `
        SELECT id, email, password_hash, name, phone, status, created_at, updated_at
        FROM customers
        WHERE email = $1
      `,
      [normalizedEmail]
    );

    return result.rows[0] ? mapCustomerRow(result.rows[0]) : null;
  }

  const result = await query(
    `
      SELECT
        p.id,
        p.email,
        p.password_hash,
        p.phone,
        p.document,
        p.company_name,
        p.bio,
        p.is_active,
        p.created_at,
        p.updated_at,
        COALESCE(array_agg(s.name ORDER BY s.name) FILTER (WHERE s.id IS NOT NULL), '{}') AS specialties
      FROM partners p
      LEFT JOIN partner_specialties ps ON ps.partner_id = p.id
      LEFT JOIN specialties s ON s.id = ps.specialty_id
      WHERE p.email = $1
      GROUP BY p.id
    `,
    [normalizedEmail]
  );

  return result.rows[0] ? mapPartnerRow(result.rows[0]) : null;
}

export async function findUserById(program, id) {
  const normalizedProgram = normalizeProgram(program);

  if (!normalizedProgram) {
    return null;
  }

  const normalizedId = String(id ?? '').trim();

  if (!normalizedId) {
    return null;
  }

  if (normalizedProgram === 'customer') {
    const result = await query(
      `
        SELECT id, email, password_hash, name, phone, status, created_at, updated_at
        FROM customers
        WHERE id = $1
      `,
      [normalizedId]
    );

    return result.rows[0] ? mapCustomerRow(result.rows[0]) : null;
  }

  const result = await query(
    `
      SELECT
        p.id,
        p.email,
        p.password_hash,
        p.phone,
        p.document,
        p.company_name,
        p.bio,
        p.is_active,
        p.created_at,
        p.updated_at,
        COALESCE(array_agg(s.name ORDER BY s.name) FILTER (WHERE s.id IS NOT NULL), '{}') AS specialties
      FROM partners p
      LEFT JOIN partner_specialties ps ON ps.partner_id = p.id
      LEFT JOIN specialties s ON s.id = ps.specialty_id
      WHERE p.id = $1
      GROUP BY p.id
    `,
    [normalizedId]
  );

  return result.rows[0] ? mapPartnerRow(result.rows[0]) : null;
}

export async function createUser(program, userData) {
  const normalizedProgram = normalizeProgram(program);

  if (!normalizedProgram) {
    const error = new Error('Programa inválido. Use customer ou partner.');
    error.code = 'INVALID_PROGRAM';
    error.status = 400;
    throw error;
  }

  const email = normalizeEmail(userData.email);

  if (normalizedProgram === 'customer') {
    try {
      const result = await query(
        `
          INSERT INTO customers (name, email, password_hash, phone, status)
          VALUES ($1, $2, $3, $4, 'active')
          RETURNING id, email, password_hash, name, phone, status, created_at, updated_at
        `,
        [userData.name, email, userData.passwordHash, userData.phone ?? null]
      );

      return mapCustomerRow(result.rows[0]);
    } catch (error) {
      if (error?.code === '23505') {
        const userExistsError = new Error('Já existe um usuário cadastrado com este e-mail para este programa.');
        userExistsError.code = 'USER_ALREADY_EXISTS';
        userExistsError.status = 409;
        throw userExistsError;
      }

      throw error;
    }
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const partnerResult = await client.query(
      `
        INSERT INTO partners (email, password_hash, phone, document, company_name, bio, is_active)
        VALUES ($1, $2, $3, $4, $5, $6, TRUE)
        RETURNING id, email, password_hash, phone, document, company_name, bio, is_active, created_at, updated_at
      `,
      [
        email,
        userData.passwordHash,
        userData.phone ?? null,
        userData.document,
        userData.companyName,
        userData.bio ?? null
      ]
    );

    const partner = partnerResult.rows[0];
    const specialties = normalizeSpecialties(userData.specialties);

    for (const specialtyName of specialties) {
      const specialtyResult = await client.query(
        `
          INSERT INTO specialties (name, is_active)
          VALUES ($1, TRUE)
          ON CONFLICT (name) DO UPDATE SET updated_at = NOW()
          RETURNING id
        `,
        [specialtyName]
      );

      await client.query(
        `
          INSERT INTO partner_specialties (partner_id, specialty_id)
          VALUES ($1, $2)
          ON CONFLICT (partner_id, specialty_id) DO NOTHING
        `,
        [partner.id, specialtyResult.rows[0].id]
      );
    }

    await client.query('COMMIT');

    return mapPartnerRow({
      ...partner,
      specialties
    });
  } catch (error) {
    await client.query('ROLLBACK');

    if (error?.code === '23505') {
      const userExistsError = new Error('Já existe um usuário cadastrado com este e-mail para este programa.');
      userExistsError.code = 'USER_ALREADY_EXISTS';
      userExistsError.status = 409;
      throw userExistsError;
    }

    throw error;
  } finally {
    client.release();
  }
}

export async function updateCustomer(id, { name, phone }) {
  const result = await query(
    `UPDATE customers
     SET name = $1, phone = $2, updated_at = NOW()
     WHERE id = $3
     RETURNING id, email, password_hash, name, phone, status, created_at, updated_at`,
    [name, phone ?? null, id]
  );
  return result.rows[0] ? mapCustomerRow(result.rows[0]) : null;
}

export async function updateCustomerPassword(id, passwordHash) {
  const result = await query(
    `UPDATE customers SET password_hash = $1, updated_at = NOW() WHERE id = $2 RETURNING id`,
    [passwordHash, id]
  );
  return result.rows[0] ?? null;
}

export function sanitizeUser(user) {
  if (!user) {
    return null;
  }

  const base = {
    id: user.id,
    program: user.program,
    email: user.email,
    phone: user.phone,
    status: user.status,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt
  };

  if (user.program === 'customer') {
    return {
      ...base,
      name: user.name
    };
  }

  return {
    ...base,
    document: user.document,
    companyName: user.companyName,
    bio: user.bio,
    specialties: user.specialties,
    isActive: user.isActive
  };
}