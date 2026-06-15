import { pool, query } from '../../config/database.js';

function mapTicketRow(row) {
  return {
    id: row.id,
    customerId: row.customer_id,
    partnerId: row.partner_id ?? null,
    specialty: row.specialty,
    title: row.title,
    description: row.description ?? null,
    status: row.status,
    addressText: row.address_text ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

export async function createTicket(data) {
  const result = await query(
    `INSERT INTO tickets (id, customer_id, specialty, title, description, address_text)
     VALUES (COALESCE($1::uuid, gen_random_uuid()), $2, $3, $4, $5, $6)
     ON CONFLICT (id) DO UPDATE SET
       customer_id = EXCLUDED.customer_id,
       specialty = EXCLUDED.specialty,
       title = EXCLUDED.title,
       description = EXCLUDED.description,
       address_text = EXCLUDED.address_text
     RETURNING *`,
    [data.id ?? null, data.customerId, data.specialty, data.title, data.description ?? null, data.addressText ?? null]
  );
  return mapTicketRow(result.rows[0]);
}

export async function findTicketById(id) {
  const result = await query('SELECT * FROM tickets WHERE id = $1', [id]);
  return result.rows[0] ? mapTicketRow(result.rows[0]) : null;
}

export async function listTickets({ customerId, partnerId, status } = {}) {
  const conditions = [];
  const params = [];

  if (customerId) {
    conditions.push(`customer_id = $${params.length + 1}`);
    params.push(customerId);
  }

  if (partnerId) {
    conditions.push(`partner_id = $${params.length + 1}`);
    params.push(partnerId);
  }

  if (status) {
    conditions.push(`status = $${params.length + 1}`);
    params.push(status);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const result = await query(
    `SELECT * FROM tickets ${where} ORDER BY created_at DESC`,
    params
  );
  return result.rows.map(mapTicketRow);
}

export async function listPendingTickets() {
  const result = await query(
    `SELECT * FROM tickets WHERE status = 'pending' ORDER BY created_at ASC`
  );
  return result.rows.map(mapTicketRow);
}

export async function updateTicketStatus(id, { status, partnerId }) {
  const result = await query(
    `UPDATE tickets
     SET status = $1,
         partner_id = COALESCE($2, partner_id),
         updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    [status, partnerId ?? null, id]
  );
  return result.rows[0] ? mapTicketRow(result.rows[0]) : null;
}
