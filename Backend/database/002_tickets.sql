-- Sprint 2: Tabela de chamados (tickets)
-- Execute este script no banco PostgreSQL após as migrações da Sprint 1

CREATE TABLE IF NOT EXISTS tickets (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID         NOT NULL,
  partner_id  UUID,
  specialty   VARCHAR(255) NOT NULL,
  title       VARCHAR(255) NOT NULL,
  description TEXT,
  status      VARCHAR(50)  NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending','accepted','in_progress','completed','cancelled')),
  address_text VARCHAR(500),
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tickets_customer_id ON tickets (customer_id);
CREATE INDEX IF NOT EXISTS idx_tickets_partner_id  ON tickets (partner_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status       ON tickets (status);

COMMENT ON TABLE  tickets              IS 'Chamados técnicos abertos por clientes';
COMMENT ON COLUMN tickets.status       IS 'pending | accepted | in_progress | completed | cancelled';
COMMENT ON COLUMN tickets.customer_id  IS 'ID do cliente que abriu o chamado (ref. customers.id)';
COMMENT ON COLUMN tickets.partner_id   IS 'ID do parceiro que aceitou o chamado (ref. partners.id)';
