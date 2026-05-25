-- Sprint 2: Adaptação da tabela tickets existente
-- Execute no SQL Editor do Supabase

-- 1. Adicionar colunas que o backend de Sprint 2 precisa
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS specialty    TEXT;
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS address_text TEXT;

-- 2. Alterar o default de status para 'pending'
ALTER TABLE tickets ALTER COLUMN status SET DEFAULT 'pending';

-- 3. Remover CHECK constraints existentes sobre status e adicionar a nova
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT tc.constraint_name
    FROM information_schema.table_constraints tc
    WHERE tc.table_name   = 'tickets'
      AND tc.table_schema = 'public'
      AND tc.constraint_type = 'CHECK'
  LOOP
    EXECUTE format('ALTER TABLE tickets DROP CONSTRAINT %I', r.constraint_name);
  END LOOP;
END$$;

ALTER TABLE tickets ADD CONSTRAINT tickets_status_check
  CHECK (status IN ('pending','accepted','in_progress','completed','cancelled','open'));

-- 4. Índices de suporte (idempotentes)
CREATE INDEX IF NOT EXISTS idx_tickets_customer_id ON tickets (customer_id);
CREATE INDEX IF NOT EXISTS idx_tickets_partner_id  ON tickets (partner_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status       ON tickets (status);
