# Sprint 2 – Integração com Middleware Orientado a Mensagens (MOM)

**Disciplina:** LDAMD – Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Aluno:** Luiz Felipe Vieira  
**Período:** 1º Semestre 2026  
**Prazo:** 25/05/2026

---

## 1. Domínio do Projeto

O sistema é uma **plataforma de chamados técnicos domiciliares**. Dois perfis de usuário interagem pela plataforma:

| Perfil | Papel |
|---|---|
| **Cliente** (`customer`) | Abre chamados informando especialidade, título, descrição e endereço |
| **Parceiro** (`partner`) | Recebe novos chamados, aceita ou recusa, executa e conclui o atendimento |

Exemplos de especialidades: elétrica, hidráulica, pintura, marcenaria.

---

## 2. MOM Escolhido: RabbitMQ

### Por que RabbitMQ?

O **RabbitMQ** foi escolhido como broker de mensagens pelos seguintes motivos:

- É o MOM mais referenciado na literatura de integração de sistemas (Hohpe & Woolf, 2003)
- Oferece **persistência de mensagens** (mensagens não são perdidas se o consumidor estiver offline)
- Possui uma **Management UI** visual (`http://localhost:15672`) que permite evidenciar o funcionamento das filas em tempo real — essencial para demonstração acadêmica
- Suporta o padrão **Topic Exchange** (pub/sub com roteamento por chave), permitindo múltiplos consumidores independentes para o mesmo evento

### Configuração do broker

| Parâmetro | Valor |
|---|---|
| Imagem | `rabbitmq:3-management-alpine` |
| Porta AMQP | `5672` |
| Porta Management UI | `15672` |
| Exchange | `chamados` (tipo: **topic**, durable) |
| Credenciais | `guest` / `guest` |

---

## 3. Eventos Implementados

O backend publica eventos em **dois momentos distintos** do fluxo de negócio.

### Evento 1 — `ticket.created`

| Atributo | Valor |
|---|---|
| **Routing key** | `ticket.created` |
| **Fila** | `ticket_created_queue` |
| **Exchange** | `chamados` |
| **Produtor** | `tickets.service.js` → `createTicket()` |
| **Consumidor** | `messaging/consumer.js` → `handleTicketCreated()` |
| **Gatilho** | `POST /tickets` concluído com sucesso |

**Payload JSON:**
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

**Ação do consumidor:** registra no log do servidor os detalhes do novo chamado. Em sprints futuras, este consumidor notificará parceiros disponíveis via WebSocket.

---

### Evento 2 — `ticket.status_changed`

| Atributo | Valor |
|---|---|
| **Routing key** | `ticket.status_changed` |
| **Fila** | `ticket_status_changed_queue` |
| **Exchange** | `chamados` |
| **Produtor** | `tickets.service.js` → `updateTicketStatus()` |
| **Consumidor** | `messaging/consumer.js` → `handleTicketStatusChanged()` |
| **Gatilho** | `PATCH /tickets/:id/status` concluído com sucesso |

**Payload JSON:**
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

**Ação do consumidor:** registra no log a transição de status (`pending → accepted`). Em sprints futuras, notificará o cliente sobre a mudança.

---

## 4. Arquitetura da Comunicação Assíncrona

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Compose                           │
│                                                                 │
│  ┌──────────────────────┐        ┌──────────────────────────┐  │
│  │   Backend (Node.js)  │        │  RabbitMQ (broker)       │  │
│  │                      │        │                          │  │
│  │  POST /tickets        │──────► │  Exchange: chamados       │  │
│  │    └─ publishEvent() │ AMQP   │  (type: topic, durable)  │  │
│  │                      │        │                          │  │
│  │  PATCH /:id/status   │──────► │  ┌─ ticket_created_queue │  │
│  │    └─ publishEvent() │        │  └─ ticket_status_queue  │  │
│  │                      │        │           │              │  │
│  │  startConsumers()    │◄───────│───────────┘              │  │
│  │    ├─ handleCreated  │ async  │  (sem REST direto)       │  │
│  │    └─ handleStatus   │        │                          │  │
│  └──────────────────────┘        └──────────────────────────┘  │
│           │ porta 3000                    │ porta 15672         │
└───────────┼───────────────────────────────┼─────────────────────┘
            ▼                               ▼
      Cliente HTTP                  Management UI
  (Postman / Swagger)           http://localhost:15672
```

**Por que isso é comunicação assíncrona de verdade?**

1. O `POST /tickets` salva o chamado no banco, chama `publishEvent()` e **retorna 201 imediatamente** ao cliente HTTP
2. O RabbitMQ entrega a mensagem para a fila `ticket_created_queue`
3. O `consumer.js` (rodando em paralelo, no mesmo processo) processa a mensagem **sem nenhuma chamada REST** — apenas consome da fila
4. Se o consumidor estiver temporariamente indisponível, a mensagem fica na fila até ser processada (graças ao `durable: true`)

---

## 5. Máquina de Estados dos Tickets

```
          [CLIENTE]            [PARCEIRO]
              │                    │
   POST /tickets                   │
              │                    │
              ▼                    │
          ┌────────┐               │
          │PENDING │◄──────────────┘
          └────┬───┘   GET /tickets?pending=true
               │
               │ PATCH /status { status: "accepted" }
               ▼
          ┌──────────┐
          │ACCEPTED  │
          └────┬─────┘
               │
               │ { status: "in_progress" }
               ▼
          ┌─────────────┐
          │ IN_PROGRESS │
          └──────┬──────┘
                 │
                 │ { status: "completed" }
                 ▼
          ┌───────────┐
          │ COMPLETED │
          └───────────┘

  Qualquer estado → CANCELLED (cliente ou parceiro)
```

Cada transição dispara um evento `ticket.status_changed` no RabbitMQ.

---

## 6. Novos Endpoints REST (Sprint 2)

| Método | Rota | Quem usa | Evento publicado |
|---|---|---|---|
| `POST` | `/tickets` | Cliente | `ticket.created` |
| `GET` | `/tickets` | Cliente / Parceiro | — |
| `GET` | `/tickets/:id` | Cliente (próprio) / Parceiro | — |
| `PATCH` | `/tickets/:id/status` | Cliente (cancelar) / Parceiro | `ticket.status_changed` |

Todos os endpoints requerem `Authorization: Bearer <token>` (JWT).

---

## 7. Como Executar (Docker Compose)

### Pré-requisitos

- Docker Desktop instalado e rodando
- Arquivo `Backend/.env` configurado (copiar de `Backend/.env.example`)

### Subir tudo com um único comando

```bash
# Na raiz do projeto
docker compose up --build
```

Isso sobe **RabbitMQ + Backend** juntos. Aguardar ~15 segundos até ver no terminal:

```
chamados-rabbitmq  | Server startup complete
chamados-backend   | Backend running on port 3000
chamados-backend   | [RabbitMQ] Conectado com sucesso.
chamados-backend   | [MOM] Consumer registrado: queue="ticket_created_queue"
chamados-backend   | [MOM] Consumer registrado: queue="ticket_status_changed_queue"
chamados-backend   | [MOM] Consumers iniciados com sucesso.
```

### URLs disponíveis

| Serviço | URL |
|---|---|
| API REST | http://localhost:3000 |
| Swagger (documentação interativa) | http://localhost:3000/docs |
| RabbitMQ Management UI | http://localhost:15672 |

**Login no RabbitMQ UI:** usuário `guest` / senha `guest`

### Parar os serviços

```bash
docker compose down          # para e remove containers (mantém dados)
docker compose down -v       # para, remove containers e apaga volumes
```

### Rodar o backend localmente (sem Docker)

```bash
# 1. Suba apenas o RabbitMQ
docker compose up rabbitmq -d

# 2. Em outro terminal
cd Backend
npm run dev
```

---

## 8. Roteiro de Teste (Postman ou Swagger)

### Fluxo completo — do chamado à conclusão

**1. Registrar cliente**
```http
POST /auth/register
{
  "program": "customer",
  "name": "Maria Silva",
  "email": "maria@teste.com",
  "password": "Senha1234"
}
```
Salve o campo `token`.

**2. Registrar parceiro**
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
Salve o campo `token`.

**3. Cliente abre chamado** *(token do cliente no header)*
```http
POST /tickets
Authorization: Bearer <token-cliente>
{
  "specialty": "Elétrica",
  "title": "Tomada com faísca na sala",
  "description": "A tomada está faiscando ao ligar aparelhos.",
  "addressText": "Rua das Flores, 123 – BH/MG"
}
```
Salve o `id` do ticket retornado.

**Evidência no terminal:**
```
[MOM][PUBLISH] ticket.created { ticketId: "...", specialty: "Elétrica", ... }
[MOM][CONSUME][ticket.created] Novo chamado #... | Especialidade: "Elétrica"
```

**4. Parceiro lista chamados pendentes** *(token do parceiro)*
```http
GET /tickets?pending=true
Authorization: Bearer <token-parceiro>
```

**5. Parceiro aceita o chamado**
```http
PATCH /tickets/<id>/status
Authorization: Bearer <token-parceiro>
{ "status": "accepted" }
```

**Evidência no terminal:**
```
[MOM][PUBLISH] ticket.status_changed { previousStatus: "pending", newStatus: "accepted" }
[MOM][CONSUME][ticket.status_changed] Chamado #... | pending → accepted
```

**6. Parceiro inicia e conclui**
```http
PATCH /tickets/<id>/status  →  { "status": "in_progress" }
PATCH /tickets/<id>/status  →  { "status": "completed" }
```
Cada requisição gera um novo par PUBLISH + CONSUME no terminal.

### Evidência visual no RabbitMQ UI

Acesse **http://localhost:15672** → aba **Queues and Streams**.  
As filas `ticket_created_queue` e `ticket_status_changed_queue` aparecem com:
- `Ready`: mensagens aguardando consumo
- `Unacked`: mensagens em processamento
- Gráfico de throughput em tempo real

---

## 9. Estrutura de Arquivos (Sprint 2)

```
Projeto_LAMD_2026_1/
├── docker-compose.yml              ← RabbitMQ + Backend (atualizado)
├── SPRINT2_RELATORIO.md            ← Este documento
├── .gitignore                      ← Atualizado (.env.example não ignorado)
└── Backend/
    ├── Dockerfile                  ← Imagem do backend (novo)
    ├── .dockerignore               ← Exclui node_modules e .env da imagem (novo)
    ├── .env.example                ← Template de variáveis de ambiente (novo)
    ├── database/
    │   └── 002_tickets.sql         ← Migration da tabela tickets (novo)
    └── src/
        ├── config/
        │   └── rabbitmq.js         ← Conexão AMQP, exchange, canais (novo)
        ├── messaging/
        │   ├── publisher.js        ← publishEvent() — produtor (novo)
        │   └── consumer.js         ← startConsumers() — consumidor (novo)
        ├── modules/
        │   └── tickets/
        │       ├── tickets.routes.js     ← Rotas REST (novo)
        │       ├── tickets.controller.js ← Controller HTTP (novo)
        │       ├── tickets.service.js    ← Lógica + disparo de eventos (novo)
        │       └── tickets.store.js      ← Queries PostgreSQL (novo)
        ├── routes/index.js         ← Atualizado: adicionado /tickets
        └── server.js               ← Atualizado: inicia consumers no boot
```

---

## 10. Relatório de Integração — Decisões de Design

### Escolha do MOM: RabbitMQ

O RabbitMQ foi escolhido por ser o broker de mensagens mais consolidado na literatura de integração empresarial (Hohpe & Woolf, 2003) e por oferecer uma Management UI que permite **evidenciar visualmente o funcionamento** das filas — essencial para o contexto acadêmico desta entrega. Alternativas como Redis Pub/Sub foram descartadas por não garantirem persistência de mensagens por padrão. Apache Kafka foi considerado desnecessário para o volume de dados e a complexidade desta etapa do projeto.

### Padrão: Topic Exchange (Publish/Subscribe com roteamento)

A escolha do **Topic Exchange** em vez de um Direct Exchange simples foi deliberada: ele permite que consumidores futuros se inscrevam em padrões de chave (ex.: `ticket.*`) sem que os produtores precisem ser alterados. Isso implementa o princípio de **desacoplamento** descrito por Richardson (2018) para arquiteturas orientadas a eventos — o serviço de tickets não conhece nem se importa com quantos consumidores existem.

### Docker Compose: hostname vs. localhost

Quando o backend roda dentro de um container Docker, ele não pode conectar ao RabbitMQ via `localhost` — precisa usar o **nome do serviço** definido no Compose (`rabbitmq`). A solução adotada foi usar `env_file` para carregar todas as variáveis do `.env` local e sobrescrever apenas `RABBITMQ_URL` com o hostname correto na seção `environment` do Compose. Dessa forma, o mesmo `.env` funciona tanto para desenvolvimento local quanto para o ambiente containerizado.

### Resiliência: backend sobe mesmo sem RabbitMQ

O `server.js` envolve o `startConsumers()` em `try/catch`: se o RabbitMQ não estiver disponível no momento do boot, o backend sobe em **modo degradado** (sem eventos) e exibe um aviso no log. Isso evita que uma falha no broker derrube toda a API REST.

---

## Referências

- HOHPE, Gregor; WOOLF, Bobby. *Enterprise Integration Patterns: designing, building, and deploying messaging solutions*. Boston: Addison-Wesley, 2003.
- RICHARDSON, Chris. *Microservices Patterns: with examples in Java*. Shelter Island: Manning, 2018.
- COULOURIS, George et al. *Distributed Systems: concepts and design*. 5. ed. Boston: Addison-Wesley, 2011.
