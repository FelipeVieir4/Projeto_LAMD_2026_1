import { query } from '../../../config/database.js';

function mapSpecialty(row) {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    isActive: row.is_active,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

export async function listSpecialties({ includeInactive = false } = {}) {
  const sql = includeInactive
    ? `
      SELECT id, name, description, is_active, created_at, updated_at
      FROM specialties
      ORDER BY name ASC
    `
    : `
      SELECT id, name, description, is_active, created_at, updated_at
      FROM specialties
      WHERE is_active = TRUE
      ORDER BY name ASC
    `;

  const result = await query(sql);
  return result.rows.map(mapSpecialty);
}

export async function createSpecialty({ name, description = null, isActive = true }) {
  const result = await query(
    `
      INSERT INTO specialties (name, description, is_active)
      VALUES ($1, $2, $3)
      RETURNING id, name, description, is_active, created_at, updated_at
    `,
    [name, description, isActive]
  );

  return mapSpecialty(result.rows[0]);
}

export async function updateSpecialty(id, { name, description, isActive }) {
  const fields = [];
  const values = [];

  if (name !== undefined) {
    fields.push(`name = $${fields.length + 1}`);
    values.push(name);
  }

  if (description !== undefined) {
    fields.push(`description = $${fields.length + 1}`);
    values.push(description);
  }

  if (isActive !== undefined) {
    fields.push(`is_active = $${fields.length + 1}`);
    values.push(isActive);
  }

  if (fields.length === 0) {
    return null;
  }

  values.push(id);

  const result = await query(
    `
      UPDATE specialties
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $${fields.length + 1}
      RETURNING id, name, description, is_active, created_at, updated_at
    `,
    values
  );

  return result.rows[0] ? mapSpecialty(result.rows[0]) : null;
}

export async function deleteSpecialty(id) {
  const result = await query('DELETE FROM specialties WHERE id = $1 RETURNING id', [id]);
  return Boolean(result.rows[0]);
}
