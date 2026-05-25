# Projeto LAMD 2026/1

Plataforma de atendimento de chamados técnicos domiciliares com roteamento por região.

## Estrutura

```
.
├── Backend/          # API REST (Node.js + Express + PostgreSQL + RabbitMQ)
├── App/              # App do cliente (em desenvolvimento)
├── App_parceiro/     # App do parceiro/técnico (em desenvolvimento)
└── reports/          # Relatórios de sprint
```

## Como executar

### Com Docker (recomendado)

```bash
# 1. Configure as variáveis de ambiente
cp Backend/.env.example Backend/.env
# Edite Backend/.env com suas credenciais do banco de dados

# 2. Suba tudo
docker compose up --build
```

Aguarde as mensagens de confirmação no terminal:

```
chamados-backend   | Backend running on port 3000
chamados-backend   | [RabbitMQ] Conectado com sucesso.
chamados-backend   | [MOM] Consumer registrado: queue="ticket_created_queue"
chamados-backend   | [MOM] Consumer registrado: queue="ticket_status_changed_queue"
```

| Serviço | URL |
|---------|-----|
| API | `http://localhost:3000/api/v1` |
| Swagger (docs interativas) | `http://localhost:3000/api/v1/docs` |
| RabbitMQ Management UI | `http://localhost:15672` (guest / guest) |

Para parar:

```bash
docker compose down        # para e remove containers (mantém dados)
docker compose down -v     # também apaga os volumes
```

### Localmente (sem Docker)

```bash
# 1. Suba apenas o RabbitMQ
docker compose up rabbitmq -d

# 2. Configure e inicie o backend
cp Backend/.env.example Backend/.env
cd Backend
npm install
npm run dev
```

## Documentação técnica

- [Diagramas de arquitetura](Backend/docs/diagrams.md)
- [Schema do banco de dados](Backend/docs/database-schema.md)
- [SQL — schema inicial](Backend/docs/sql/001_initial_schema.sql)
- [SQL — tickets](Backend/docs/sql/002_tickets.sql)

## Relatórios de sprint

- [Sprint 1 — Auth, Especialidades e Infraestrutura](reports/SPRINT1_RELATORIO.md)
- [Sprint 2 — Integração com RabbitMQ (MOM)](reports/SPRINT2_RELATORIO.md)
