# Backend

API REST do projeto em Node.js + Express + PostgreSQL + RabbitMQ.

## Configuração

```bash
cp .env.example .env
# Edite .env com as credenciais do banco e as chaves de segurança
```

## Execução

**Com Docker (recomendado):** veja o [README raiz](../README.md).

**Local:**

```bash
npm install
npm run dev   # modo watch
npm start     # produção
```

A API sobe em `http://localhost:3000/api/v1`.

## Endpoints

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| `GET` | `/api/v1/health` | — | Health check |
| **Auth** |
| `POST` | `/api/v1/auth/register` | — | Cadastro (cliente ou parceiro) |
| `POST` | `/api/v1/auth/login` | — | Login → retorna JWT |
| `GET` | `/api/v1/auth/me` | JWT | Dados da conta autenticada |
| `PATCH` | `/api/v1/auth/profile` | JWT | Atualiza dados do perfil (cliente: nome/telefone; parceiro: empresa/telefone/bio) |
| `PATCH` | `/api/v1/auth/password` | JWT | Altera senha (requer senha atual) — cliente ou parceiro |
| **Especialidades** |
| `GET` | `/api/v1/specialties` | — | Lista especialidades ativas (público) |
| **Admin — Especialidades** |
| `GET` | `/api/v1/admin/specialties` | JWT + admin-key | Lista todas especialidades |
| `POST` | `/api/v1/admin/specialties` | JWT + admin-key | Cria especialidade |
| `PUT` | `/api/v1/admin/specialties/:id` | JWT + admin-key | Atualiza especialidade |
| `DELETE` | `/api/v1/admin/specialties/:id` | JWT + admin-key | Remove especialidade |
| **Tickets** |
| `POST` | `/api/v1/tickets` | JWT | Abre chamado (cliente) |
| `GET` | `/api/v1/tickets` | JWT | Lista chamados do usuário |
| `GET` | `/api/v1/tickets/:id` | JWT | Detalhes do chamado |
| `PATCH` | `/api/v1/tickets/:id/status` | JWT | Atualiza status |

Documentação interativa: `http://localhost:3000/api/v1/docs`

## Autenticação

- Rotas públicas: `register` e `login`
- Rotas protegidas: `Authorization: Bearer <token>`
- Rotas admin: JWT + header `x-admin-key: <ADMIN_API_KEY>`

O campo `program` diferencia o tipo de conta: `customer` (cliente) ou `partner` (parceiro).

## Mensageria (RabbitMQ)

O backend publica eventos no exchange `chamados` (type: `topic`, durable).

| Evento (routing key) | Gatilho | Fila consumidora |
|----------------------|---------|-----------------|
| `ticket.created` | `POST /api/v1/tickets` | `ticket_created_queue` |
| `ticket.status_changed` | `PATCH /api/v1/tickets/:id/status` | `ticket_status_changed_queue` |

Os consumers são iniciados automaticamente no boot do servidor.

## Tempo real (WebSocket)

Além do REST, o backend expõe um servidor WebSocket em `/ws` (mesma porta da API) que repassa, em tempo real, os eventos consumidos do RabbitMQ — eliminando a necessidade de polling contínuo nos apps:

- Conexão: `ws://<host>:3000/ws?token=<JWT>`
- Apps com `program=partner` recebem `ticket.created` (novo chamado na fila de pendentes) e `ticket.status_changed` (chamado saiu da fila porque outro parceiro aceitou).
- Apps com `program=customer` recebem `ticket.status_changed` referente aos seus próprios chamados (ex.: parceiro aceitou/concluiu).

Fluxo: `tickets.service.js` publica o evento no exchange `chamados` → `messaging/consumer.js` consome a fila → `realtime/ws.js` distribui a mensagem aos sockets conectados (`broadcastToPartners` / `broadcastToCustomer`).

## Variáveis de ambiente

| Variável | Descrição |
|----------|-----------|
| `PORT` | Porta da API (padrão: `3000`) |
| `DATABASE_URL` | Connection string PostgreSQL/Supabase |
| `JWT_SECRET` | Segredo para assinar tokens JWT |
| `ADMIN_API_KEY` | Chave para rotas administrativas |
| `RABBITMQ_URL` | Connection string AMQP (padrão local: `amqp://guest:guest@localhost:5672`) |

## Coleta de testes

- Postman: `docs/tests/LAMD_2026_1.postman_collection.json`
