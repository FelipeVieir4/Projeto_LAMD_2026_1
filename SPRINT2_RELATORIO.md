# Sprint 2 – Integração com Middleware Orientado a Mensagens (MOM)

**Disciplina:** LDAMD – Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Aluno:** Luiz Felipe Vieira  
**Período:** 1º Semestre 2026  
**Data de entrega:** 25/05/2026  

---

## 1. O que foi implementado

### 1.1 Domínio do projeto

O sistema é uma **plataforma de chamados técnicos domiciliares** (ex.: elétrica, hidráulica, pintura). Dois perfis de usuário:

- **Cliente (`customer`)** – abre chamados informando a especialidade, título, descrição e endereço.
- **Parceiro (`partner`)** – recebe notificações de novos chamados, aceita, executa e conclui o atendimento.

### 1.2 Middleware Orientado a Mensagens (MOM) — RabbitMQ

O MOM escolhido foi o **RabbitMQ**, executado via Docker. Configuração:

| Parâmetro | Valor |
|---|---|
| Imagem Docker | `rabbitmq:3-management-alpine` |
| Porta AMQP | `5672` |
| Porta Management UI | `15672` |
| Exchange | `chamados` (tipo: **topic**, durable) |
| Usuário | `admin` / `admin123` |

A escolha do tipo **topic exchange** permite rotear mensagens por padrão de chave (ex.: `ticket.*`), facilitando adicionar novos consumidores no futuro sem alterar os produtores.

### 1.3 Eventos implementados

Dois eventos são publicados em momentos distintos do fluxo de negócio:

#### Evento 1 – `ticket.created`

| Campo | Valor |
|---|---|
| **Nome do evento** | `ticket.created` |
| **Produtor** | `tickets.service.js` → método `createTicket()` |
| **Consumidor** | `messaging/consumer.js` → `handleTicketCreated()` |
| **Fila** | `ticket_created_queue` |
| **Exchange** | `chamados` |
| **Routing key** | `ticket.created` |

**Payload JSON de exemplo:**
```json
{
  "ticketId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "customerId": "c0a80101-0000-0000-0000-000000000001",
  "specialty": "Elétrica",
  "title": "Tomada com faísca na sala",
  "description": "A tomada da sala está faiscando ao ligar qualquer aparelho.",
  "addressText": "Rua das Flores, 123 – Belo Horizonte/MG",
  "createdAt": "2026-05-24T14:30:00.000Z",
  "_meta": {
    "event": "ticket.created",
    "publishedAt": "2026-05-24T14:30:00.050Z"
  }
}
```

**Quando é disparado:** imediatamente após o cliente fazer `POST /tickets` com sucesso.  
**Ação do consumidor:** loga o novo chamado no servidor, identificando id, especialidade e cliente. Em sprints futuras, notificará os parceiros via WebSocket/push.

---

#### Evento 2 – `ticket.status_changed`

| Campo | Valor |
|---|---|
| **Nome do evento** | `ticket.status_changed` |
| **Produtor** | `tickets.service.js` → método `updateTicketStatus()` |
| **Consumidor** | `messaging/consumer.js` → `handleTicketStatusChanged()` |
| **Fila** | `ticket_status_changed_queue` |
| **Exchange** | `chamados` |
| **Routing key** | `ticket.status_changed` |

**Payload JSON de exemplo:**
```json
{
  "ticketId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "previousStatus": "pending",
  "newStatus": "accepted",
  "updatedBy": "p0a80202-0000-0000-0000-000000000002",
  "updatedByProgram": "partner",
  "partnerId": "p0a80202-0000-0000-0000-000000000002",
  "updatedAt": "2026-05-24T14:35:00.000Z",
  "_meta": {
    "event": "ticket.status_changed",
    "publishedAt": "2026-05-24T14:35:00.030Z"
  }
}
```

**Quando é disparado:** toda vez que `PATCH /tickets/:id/status` é chamado com sucesso.  
**Ação do consumidor:** loga a transição de status. Maquina de estados válida: `pending → accepted → in_progress → completed` (ou `cancelled` em qualquer etapa).

---

## 2. Arquitetura do MOM

```
Cliente HTTP          Backend (Express + Node.js)          RabbitMQ
─────────────         ───────────────────────────          ────────────────────────
                                                            Exchange: chamados (topic)
POST /tickets    ──►  tickets.service.createTicket()  ──►  routing key: ticket.created
                              │                                      │
                              │ persiste no PostgreSQL               ▼
                              │                            Queue: ticket_created_queue
                                                                     │
PATCH /tickets                                                        │ (async)
/:id/status      ──►  tickets.service.updateStatus()                 ▼
                              │                       consumer.handleTicketCreated()
                              │ atualiza no PostgreSQL     [log no terminal]
                              │
                              └──►  routing key: ticket.status_changed
                                             │
                                             ▼
                                   Queue: ticket_status_changed_queue
                                             │
                                             │ (async)
                                             ▼
                                   consumer.handleTicketStatusChanged()
                                       [log no terminal]
```

**Ponto-chave da assincronicidade:** o produtor (`tickets.service.js`) publica a mensagem no exchange e **retorna imediatamente** para o cliente HTTP. O consumidor processa a mensagem **em paralelo**, sem bloqueio da requisição REST. Não há chamada REST direta entre produtor e consumidor.

---

## 3. Módulo de Tickets (novos endpoints REST)

Todos os endpoints requerem autenticação JWT (`Authorization: Bearer <token>`).

| Método | Rota | Quem pode usar | Dispara evento? |
|---|---|---|---|
| `POST` | `/tickets` | Cliente | `ticket.created` |
| `GET` | `/tickets` | Cliente / Parceiro | — |
| `GET` | `/tickets/:id` | Cliente (próprio) / Parceiro | — |
| `PATCH` | `/tickets/:id/status` | Cliente (cancelar) / Parceiro | `ticket.status_changed` |

### Máquina de estados do ticket

```
[pending] → accepted → in_progress → completed
     ↓           ↓           ↓
  cancelled   cancelled   cancelled
```

---

## 4. Como testar

### 4.1 Pré-requisitos

- Node.js 18+
- Docker (para o RabbitMQ)
- PostgreSQL acessível (já configurado via Supabase no `.env`)

### 4.2 Passo a passo

#### Passo 1 — Subir o RabbitMQ

```bash
# Na raiz do projeto (onde está o docker-compose.yml)
docker compose up -d
```

Aguardar ~10 segundos. Verifique o painel em: **http://localhost:15672**  
Login: `admin` / Senha: `admin123`

#### Passo 2 — Executar a migration do banco

No Supabase (ou no seu PostgreSQL), execute o arquivo:

```
Backend/database/002_tickets.sql
```

Você pode rodar via **SQL Editor do Supabase** colando o conteúdo do arquivo.

#### Passo 3 — Iniciar o backend

```bash
cd Backend
npm run dev
```

Você verá no terminal:
```
Backend running on port 3000
[RabbitMQ] Conectado com sucesso.
[MOM] Consumer registrado: queue="ticket_created_queue" routingKey="ticket.created"
[MOM] Consumer registrado: queue="ticket_status_changed_queue" routingKey="ticket.status_changed"
[MOM] Consumers iniciados com sucesso.
```

#### Passo 4 — Testar via Postman / Swagger

Acesse o Swagger: **http://localhost:3000/docs**

**Fluxo completo de teste:**

**1. Registrar um cliente:**
```http
POST /auth/register
{
  "program": "customer",
  "name": "Maria Silva",
  "email": "maria@teste.com",
  "password": "Senha1234"
}
```
Salve o `token` retornado.

**2. Registrar um parceiro:**
```http
POST /auth/register
{
  "program": "partner",
  "companyName": "Elétrica Silva LTDA",
  "document": "12.345.678/0001-90",
  "email": "parceiro@teste.com",
  "password": "Senha1234",
  "specialties": ["Elétrica", "Hidráulica"]
}
```
Salve o `token` retornado.

**3. Cliente cria um chamado** (use o token do cliente):
```http
POST /tickets
Authorization: Bearer <token-do-cliente>
{
  "specialty": "Elétrica",
  "title": "Tomada com faísca na sala",
  "description": "A tomada está faiscando ao ligar aparelhos.",
  "addressText": "Rua das Flores, 123 – BH/MG"
}
```
**→ Observe no terminal do backend:** mensagem `[MOM][PUBLISH] ticket.created` seguida de `[MOM][CONSUME][ticket.created]`

**4. Parceiro lista chamados pendentes** (use o token do parceiro):
```http
GET /tickets?pending=true
Authorization: Bearer <token-do-parceiro>
```

**5. Parceiro aceita o chamado** (use o `id` retornado no passo 3):
```http
PATCH /tickets/<id>/status
Authorization: Bearer <token-do-parceiro>
{
  "status": "accepted"
}
```
**→ Observe no terminal:** `[MOM][PUBLISH] ticket.status_changed` + `[MOM][CONSUME][ticket.status_changed] pending → accepted`

**6. Parceiro inicia e conclui:**
```http
PATCH /tickets/<id>/status  →  { "status": "in_progress" }
PATCH /tickets/<id>/status  →  { "status": "completed" }
```
Cada PATCH gera um novo evento no terminal.

#### Passo 5 — Evidência no RabbitMQ Management UI

Acesse **http://localhost:15672** → aba **Queues**.  
As filas `ticket_created_queue` e `ticket_status_changed_queue` devem aparecer com contadores de mensagens.

---

## 5. Estrutura de arquivos adicionados na Sprint 2

```
Projeto_LAMD_2026_1/
├── docker-compose.yml                          ← RabbitMQ (novo)
├── SPRINT2_RELATORIO.md                        ← Este arquivo
└── Backend/
    ├── .env.example                            ← Variáveis de ambiente documentadas (novo)
    ├── database/
    │   └── 002_tickets.sql                     ← Migration da tabela tickets (novo)
    └── src/
        ├── config/
        │   └── rabbitmq.js                     ← Conexão e canais RabbitMQ (novo)
        ├── messaging/
        │   ├── publisher.js                    ← Produtor de eventos (novo)
        │   └── consumer.js                     ← Consumidor de eventos (novo)
        ├── modules/
        │   └── tickets/
        │       ├── tickets.routes.js           ← Rotas REST (novo)
        │       ├── tickets.controller.js       ← Controller (novo)
        │       ├── tickets.service.js          ← Lógica + disparo de eventos (novo)
        │       └── tickets.store.js            ← Queries PostgreSQL (novo)
        ├── routes/index.js                     ← Atualizado: adicionado /tickets
        └── server.js                           ← Atualizado: inicia consumers
```

---

## 6. Relatório de Integração — Decisões de Design

### Escolha do MOM: RabbitMQ

O RabbitMQ foi escolhido por ser o broker de mensagens mais citado na literatura de integração (Hohpe & Woolf, 2003) e por oferecer uma Management UI que facilita a **evidência visual** do funcionamento — fundamental para a avaliação acadêmica. Alternativas como Redis Pub/Sub foram descartadas por não oferecerem persistência de mensagens por padrão, e alternativas como Kafka foram consideradas desnecessárias para o volume de dados desta aplicação.

### Padrão utilizado: Topic Exchange

O padrão **Publish/Subscribe com Topic Exchange** permite que um produtor publique um evento com uma routing key (ex.: `ticket.created`) e múltiplos consumidores se inscrevam em padrões de chave (ex.: `ticket.*`). Isso desacopla produtores de consumidores — o serviço de tickets não sabe quantos consumidores existem, nem o que eles fazem com o evento.

### Desafios encontrados

1. **Resiliência na inicialização:** o backend poderia falhar se o RabbitMQ não estivesse pronto. Solução: o `server.js` trata o erro de conexão com um `try/catch` e exibe um aviso, permitindo que o backend suba normalmente sem o MOM (degradado, sem eventos).
2. **Canais separados para publisher e consumer:** o amqplib recomenda não compartilhar canais entre produção e consumo. A solução foi criar um canal dedicado para cada finalidade: `getPublisherChannel()` (singleton reutilizado) e `createConsumerChannel()` (um por sessão de consumo).
3. **Idempotência do exchange:** o `assertExchange()` é chamado tanto no publisher quanto no consumer para garantir que o exchange exista antes de qualquer operação, independentemente da ordem de inicialização.

### Referências

- HOHPE, Gregor; WOOLF, Bobby. *Enterprise Integration Patterns*. Addison-Wesley, 2003.
- RICHARDSON, Chris. *Microservices Patterns*. Manning, 2018.
- COULOURIS, George et al. *Distributed Systems: concepts and design*. 5. ed. Addison-Wesley, 2011.
