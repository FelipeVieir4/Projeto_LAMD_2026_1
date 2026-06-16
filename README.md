# Fixit LAMD 2026/1

Plataforma de atendimento de chamados técnicos domiciliares com roteamento por região.

## Estrutura

```
.
├── Backend/          # API REST + worker assíncrono (Node.js + Express + PostgreSQL + RabbitMQ)
├── App/              # App do cliente — Flutter, offline-first (funcional)
├── App_parceiro/     # App do parceiro/técnico (em desenvolvimento)
└── reports/          # Relatórios de sprint
```

## Como executar

### Backend com Docker (recomendado)

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

### Backend local (sem Docker)

```bash
# 1. Suba apenas o RabbitMQ
docker compose up rabbitmq -d

# 2. Configure e inicie o backend
cp Backend/.env.example Backend/.env
cd Backend
npm install
npm run dev
```

### App Flutter (cliente)

```bash
cd App
flutter pub get
flutter run   # com emulador/dispositivo conectado
```

> A `baseUrl` está em `App/lib/core/constants.dart`.
> Para emulador Android use `http://10.0.2.2:3000/api/v1`; para dispositivo físico, use o IP da máquina na rede local.

## App móvel (Fixit LAMD)

O app cliente foi construído com Flutter e segue arquitetura **offline-first**:

- Abre e lista chamados mesmo sem conexão (SQLite local)
- Sincronização automática via polling quando a rede retorna
- 8 telas: Splash, Login, Registro, Home (dashboard), Chamados, Criar Chamado, Detalhes, Perfil
- Navegação por bottom navigation bar com rotas nomeadas
- Edição de perfil (nome/telefone) e troca de senha diretamente no app

## Documentação técnica

- [Diagramas de arquitetura](Backend/docs/diagrams.md)
- [Schema do banco de dados](Backend/docs/database-schema.md)
- [SQL — schema inicial](Backend/docs/sql/001_initial_schema.sql)
- [SQL — tickets](Backend/docs/sql/002_tickets.sql)

## Relatórios de sprint

- [Sprint 1 — Auth, Especialidades e Infraestrutura](reports/SPRINT1_RELATORIO.md)
- [Sprint 2 — Integração com RabbitMQ (MOM)](reports/SPRINT2_RELATORIO.md)
- [Sprint 3 — App Flutter Offline-First, UI e Perfil](reports/SPRINT3_RELATORIO.md)
