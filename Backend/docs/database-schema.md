# Schema Inicial Do Banco

Este schema cobre o MVP do sistema de chamados com roteamento por região.

## Entidades Principais

### customers

Guarda as contas do App do cliente.

- `id`
- `name`
- `email`
- `password_hash`
- `phone`
- `status` - active, blocked, pending
- `created_at`
- `updated_at`

### partners

Representa a conta do App_parceiro e o cadastro do prestador de serviço.

- `id`
- `email`
- `password_hash`
- `phone`
- `document`
- `company_name`
- `bio`
- `specialties`
- `is_active`
- `created_at`
- `updated_at`

### regions

Define a área atendida pelo parceiro.

- `id`
- `name`
- `type` - cep, neighborhood, polygon
- `cep_prefix`
- `neighborhood`
- `polygon_geojson`
- `is_active`
- `created_at`
- `updated_at`

### services

Catálogo de serviços tabelados.

- `id`
- `name`
- `description`
- `base_price`
- `estimated_minutes`
- `is_active`
- `created_at`
- `updated_at`

### partner_regions

Relaciona parceiros e regiões.

- `partner_id`
- `region_id`
- `created_at`

### tickets

É o chamado aberto pelo cliente.

- `id`
- `customer_id`
- `region_id`
- `service_id`
- `partner_id` - nullable até a aceitação
- `title`
- `description`
- `cep`
- `neighborhood`
- `address`
- `latitude`
- `longitude`
- `status` - open, analyzing, sent, accepted, in_progress, completed, canceled
- `priority`
- `opened_at`
- `accepted_at`
- `started_at`
- `finished_at`
- `created_at`
- `updated_at`

### ticket_status_history

Mantém o histórico de mudança de status.

- `id`
- `ticket_id`
- `status`
- `changed_by_customer_id`
- `changed_by_partner_id`
- `note`
- `created_at`

### notifications

Registra as notificações enviadas para parceiros.

- `id`
- `ticket_id`
- `partner_id`
- `channel` - push, email, whatsapp, in_app
- `status` - pending, sent, read, failed
- `sent_at`
- `read_at`
- `created_at`

## Relacionamentos

- Um `customer` pode ter muitos `tickets`.
- Um `partner` pode estar em várias `regions`.
- Uma `region` pode ter vários `partners`.
- Um `service` pode estar em vários `tickets`.
- Um `ticket` pertence a um `customer`, uma `region` e um `service`.
- Um `ticket` pode ser atribuído a um `partner` depois da aceitação.
- Um `ticket` pode ter várias entradas em `ticket_status_history`.
- Um `ticket` pode gerar várias `notifications`.

## Regras De Banco

- `customers.email` deve ser único.
- `partners.email` deve ser único.
- `tickets.partner_id` começa nulo e só é preenchido quando o técnico aceita.
- `ticket_status_history` nunca deve perder o status anterior.
- `regions` precisam suportar pelo menos CEP, bairro ou polígono para o roteamento.
