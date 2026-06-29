# App_parceiro

Aplicativo Flutter do prestador de serviço (Fixit LAMD — Parceiro), integrado à mesma API REST do `App/` (cliente) e notificado em tempo real via WebSocket alimentado pelos eventos do RabbitMQ.

## Funcionalidades

- Cadastro/login de parceiro (`program=partner`), com especialidades
- **Pendentes**: lista de chamados aguardando aceite, atualizada automaticamente quando o backend publica `ticket.created` (sem polling manual)
- **Detalhes do chamado**: aceitar ou recusar; ao aceitar, o chamado passa a pertencer ao parceiro
- **Meus serviços**: acompanhamento dos chamados aceitos — iniciar atendimento e concluir
- **Perfil**: editar dados da empresa, telefone e bio; alterar senha

## Arquitetura

```
lib/
├── core/            constants.dart (baseUrl/wsUrl), theme.dart
├── data/
│   ├── local/       local_database.dart (cache SQLite de chamados)
│   ├── remote/      api_client.dart (REST + JWT)
│   └── repositories/
│       ├── auth_repository.dart       login, registro, perfil, senha
│       ├── tickets_repository.dart    pendentes, meus serviços, aceitar/avançar status
│       └── realtime_repository.dart   cliente WebSocket (com reconexão automática)
├── models/          user.dart, ticket.dart
├── screens/         splash, login, register, pending, ticket_detail, jobs, profile
└── widgets/         app_bottom_nav.dart, ticket_card.dart, status_chip.dart
```

## Notificação assíncrona (MOM → WebSocket → App)

```
Cliente cria chamado → POST /tickets → publishEvent('ticket.created') no RabbitMQ
  → consumer.js consome a fila → ws.js faz broadcastToPartners('ticket.created', payload)
  → App do parceiro recebe no RealtimeRepository → lista de Pendentes atualiza sozinha

Parceiro aceita (PATCH /tickets/:id/status) → publishEvent('ticket.status_changed')
  → consumer.js consome → ws.js faz broadcastToCustomer(customerId, ...)
  → App do cliente é avisado da mudança de status do seu chamado
```

Caso o WebSocket esteja indisponível, a tela de Pendentes mantém uma reconsulta de segurança a cada 30s — mas o caminho principal de notificação é orientado a eventos (MOM/WebSocket), não polling.

## Como executar

```bash
cd App_parceiro
flutter pub get
flutter run
```

> `lib/core/constants.dart` define `baseUrl` e `wsUrl`.
> Emulador Android: `10.0.2.2` aponta para o host. Dispositivo físico: use o IP da máquina que roda o backend.

Pré-requisito: backend e RabbitMQ no ar (`docker compose up --build` na raiz do projeto).
