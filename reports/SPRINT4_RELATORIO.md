# Sprint 4 – App do Parceiro, Notificação em Tempo Real e Integração Final

**Disciplina:** LDAMD – Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas
**Aluno:** Luiz Felipe Vieira
**Período:** 1º Semestre 2026
**Prazo:** 03/07/2026

---

## 1. Domínio do Projeto

O sistema é uma **plataforma de chamados técnicos domiciliares**. Dois perfis de usuário interagem pela plataforma:

| Perfil | Papel |
|---|---|
| **Cliente** (`customer`) | Abre chamados informando especialidade, título, descrição e endereço |
| **Parceiro** (`partner`) | Recebe novos chamados, aceita ou recusa, executa e conclui o atendimento |

Esta sprint conclui o ciclo iniciado nas Sprints 1–3: o backend REST (Sprint 1), a integração com o MOM (Sprint 2) e o app Flutter do cliente (Sprint 3) agora se conectam ao último componente obrigatório — o **app Flutter do parceiro** — fechando o fluxo de ponta a ponta orientado a eventos.

---

## 2. Objetivo da Sprint 4

- Construir o **app Flutter do parceiro** (`App_parceiro/`), com lista de pendentes, detalhes/aceite e acompanhamento de serviços
- Garantir que o parceiro seja **notificado de forma assíncrona** (via MOM/evento), sem depender de polling manual
- Demonstrar o **fluxo completo de ponta a ponta**: cliente cria chamado → backend publica evento no MOM → parceiro é notificado → parceiro aceita → cliente é notificado da atualização
- Produzir este relatório técnico final, refletindo sobre os padrões arquiteturais estudados ao longo do semestre

---

## 3. O que foi construído

### 3.1 App Flutter do Parceiro (`App_parceiro/`)

| Tela | Arquivo | Função |
|---|---|---|
| **Splash** | `splash_screen.dart` | Verifica token salvo → redireciona para Pendentes ou Login |
| **Login** | `login_screen.dart` | Autenticação com JWT, `program=partner` |
| **Registro** | `register_screen.dart` | Cadastro de parceiro (empresa, documento, especialidades) |
| **Pendentes** | `pending_screen.dart` | Lista de chamados aguardando aceite, com **filtro por especialidade** e atualização em tempo real |
| **Detalhes** | `ticket_detail_screen.dart` | Aceitar/recusar (se `pending`); iniciar/concluir atendimento (se `accepted`/`in_progress`) |
| **Meus serviços** | `jobs_screen.dart` | Chamados assumidos pelo parceiro, filtrados por "Em andamento" / "Concluídos" |
| **Perfil** | `profile_screen.dart` | Editar empresa/telefone/bio; alterar senha; logout |

#### Camada de dados

| Arquivo | Função |
|---|---|
| `data/remote/api_client.dart` | Wrapper HTTP com injeção automática de JWT |
| `data/repositories/auth_repository.dart` | Login, registro, perfil e senha do parceiro |
| `data/repositories/tickets_repository.dart` | Pendentes (pool compartilhado), meus serviços, transições de status |
| `data/repositories/realtime_repository.dart` | Cliente WebSocket com reconexão automática |
| `data/local/local_database.dart` | Cache SQLite (`sqflite`) dos chamados pendentes e assumidos |

### 3.2 Backend — Ponte de tempo real (`Backend/src/realtime/ws.js`)

O requisito mais sensível da Sprint 4 é a **notificação assíncrona via MOM/evento**. Em vez de o app do parceiro fazer polling contínuo em `GET /tickets?pending=true`, o backend passou a expor um servidor WebSocket (`/ws`, mesma porta da API REST) que é alimentado diretamente pelos *consumers* do RabbitMQ:

```
tickets.service.js  →  publishEvent()  →  RabbitMQ (exchange "chamados")
                                                │
                                                ▼
                                  messaging/consumer.js (consome a fila)
                                                │
                          ┌─────────────────────┴─────────────────────┐
                          ▼                                           ▼
        broadcastToPartners(event, payload)          broadcastToCustomer(customerId, event, payload)
                          │                                           │
                          ▼                                           ▼
                App do Parceiro (WS)                         App do Cliente (WS)
```

Não existe nenhuma chamada REST entre o consumidor do evento e o app — a entrega é feita por *push* no socket já aberto, exatamente como a especificação pede ("sem que o prestador precise atualizar manualmente a tela").

### 3.3 Backend — Perfil do parceiro

Antes desta sprint, `PATCH /auth/profile` e `PATCH /auth/password` só funcionavam para `customer` (limitação herdada da Sprint 3). Foram estendidos para parceiros, permitindo editar `companyName`, `phone`, `bio` e trocar senha — necessário para a tela de Perfil do novo app.

---

## 4. Arquitetura Final do Sistema

```
┌─────────────────┐        REST (JWT)         ┌───────────────────────────┐
│   App Cliente    │ ────────────────────────► │                            │
│   (Flutter)      │ ◄──────────────────────── │      Backend Node.js       │
└────────┬─────────┘        WebSocket           │   (Express + ws + amqplib) │
         │            ◄──────────────────────── │                            │
         │ ticket.status_changed                └─────────────┬──────────────┘
         │                                                     │
         │                                          REST (JWT) │  AMQP
         │                                                     │
┌────────┴─────────┐        REST (JWT)         ┌──────────────┴─────────────┐
│  App Parceiro     │ ────────────────────────► │   RabbitMQ (exchange       │
│  (Flutter)        │ ◄──────────────────────── │   "chamados", topic)       │
└──────────────────┘        WebSocket            └─────────────────────────────┘
   ticket.created /
   ticket.status_changed                          ┌─────────────────────────────┐
                                                    │   PostgreSQL (Supabase)     │
                                                    └─────────────────────────────┘
```

Cada app conversa com o backend por dois canais complementares: **REST** para ações que o usuário dispara deliberadamente (criar chamado, aceitar, mudar status, editar perfil) e **WebSocket** para receber, de forma passiva e assíncrona, o reflexo dos eventos que o *outro lado* da transação publicou no MOM.

---

## 5. Fluxo Completo de Ponta a Ponta

Sequência validada manualmente (registro de cliente e parceiro, criação de chamado, aceite) com evidência nos logs do backend:

1. **Cliente cria chamado** → `POST /tickets` → `publishEvent(TICKET_CREATION_REQUESTED)`
2. **Consumer** processa, grava no Postgres, publica `TICKET_CREATED`
3. **Consumer** consome `TICKET_CREATED` → `broadcastToPartners('ticket.created', payload)`
4. **App do Parceiro**, com socket aberto em `/ws`, recebe a mensagem instantaneamente e atualiza a aba **Pendentes** (sem polling)
5. **Parceiro aceita** → `PATCH /tickets/:id/status {status: "accepted"}` → `publishEvent(TICKET_STATUS_CHANGE_REQUESTED)`
6. **Consumer** processa, grava `partner_id` e novo status, publica `TICKET_STATUS_CHANGED` (agora incluindo `customerId` para roteamento)
7. **Consumer** consome `TICKET_STATUS_CHANGED` → `broadcastToCustomer(customerId, ...)` e também `broadcastToPartners(...)` (para os demais parceiros removerem o chamado da fila de pendentes)
8. **App do Cliente** recebe a atualização e reflete o novo status do seu chamado

Evidência real de log (ambiente local, RabbitMQ + Postgres via Docker Compose):

```
[MOM][PUBLISH] ticket.created {"ticketId":"...","specialty":"Elétrica","title":"Tomada queimada", ...}
[MOM][CONSUME][ticket.created] Novo chamado #... criado | Especialidade: "Elétrica" | ...
[WS][BROADCAST→partners] ticket.created (1 conectado(s))

[MOM][PUBLISH] ticket.status_changed {"previousStatus":"pending","newStatus":"accepted", ...}
[MOM][CONSUME][ticket.status_changed] Chamado #... | pending → accepted | Atualizado por: ... (partner)
[WS][BROADCAST→partners] ticket.status_changed (1 conectado(s))
```

Um cliente WebSocket de teste (script Node com a lib `ws`), autenticado com o token do parceiro, recebeu a mensagem `ticket.created` em menos de 100ms após o `POST /tickets` do cliente — confirmando que a notificação é orientada a evento, e não a um intervalo de verificação.

---

## 6. Estrutura de Arquivos (Sprint 4)

```
Projeto_LAMD_2026_1/
├── reports/
│   └── SPRINT4_RELATORIO.md
├── App_parceiro/
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── constants.dart            ← baseUrl + wsUrl
│       │   └── theme.dart                ← paleta própria (#0E7C61)
│       ├── data/
│       │   ├── local/local_database.dart
│       │   ├── remote/api_client.dart
│       │   └── repositories/
│       │       ├── auth_repository.dart
│       │       ├── tickets_repository.dart
│       │       └── realtime_repository.dart   ← cliente WebSocket
│       ├── models/
│       │   ├── ticket.dart
│       │   └── user.dart
│       ├── screens/
│       │   ├── splash_screen.dart
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   ├── pending_screen.dart        ← tempo real + filtro de especialidade
│       │   ├── ticket_detail_screen.dart  ← aceitar/recusar/avançar
│       │   ├── jobs_screen.dart
│       │   └── profile_screen.dart
│       └── widgets/
│           ├── app_bottom_nav.dart
│           ├── ticket_card.dart
│           └── status_chip.dart
└── Backend/
    └── src/
        ├── realtime/
        │   └── ws.js                     ← novo: servidor WebSocket
        ├── messaging/consumer.js          ← atualizado: chama broadcastToPartners/Customer
        ├── modules/tickets/tickets.service.js  ← atualizado: customerId no payload de status_changed
        └── modules/auth/
            ├── auth.service.js            ← atualizado: perfil/senha para parceiro
            └── auth.store.js              ← novo: updatePartner, updatePartnerPassword
```

---

## 7. Como Executar

### Backend + MOM
```bash
# Na raiz do projeto
docker compose up --build
```
API: `http://localhost:3000/api/v1` · Swagger: `/api/v1/docs` · RabbitMQ UI: `http://localhost:15672` · WebSocket: `ws://localhost:3000/ws?token=<JWT>`

### App Cliente
```bash
cd App
flutter pub get
flutter run
```

### App Parceiro
```bash
cd App_parceiro
flutter pub get
flutter run
```

Para a demonstração em screencast, os dois apps rodam em emuladores distintos simultaneamente, ambos apontando para o mesmo backend (`10.0.2.2:3000` no emulador Android).

---

## 8. Decisões de Design

### WebSocket alimentado pelo consumer, não pela rota REST

A notificação ao parceiro poderia ter sido implementada de forma mais simples — bastaria que o controller de `POST /tickets` chamasse `broadcastToPartners` diretamente após salvar o ticket. Optou-se deliberadamente por **disparar o broadcast dentro do consumidor do RabbitMQ** (`handleTicketCreated`, em `consumer.js`), e não no controller HTTP. Isso preserva o princípio central da Sprint 2: o evento de domínio é o que dispara efeitos colaterais, e o WebSocket é apenas **mais um consumidor** do mesmo evento publicado no MOM — o controller continua agnóstico de quem está "ouvindo".

### Autenticação do WebSocket via JWT na query string

Como o protocolo WebSocket não permite cabeçalhos customizados na fase de handshake em todos os clientes Flutter de forma simples, o token é enviado como parâmetro de busca (`?token=`). O servidor reaproveita o mesmo `jwt.verify` usado nas rotas REST, evitando duplicar lógica de autenticação.

### "Recusar" um chamado não chama a API

No pool de chamados pendentes, qualquer parceiro pode ver e aceitar qualquer chamado (não há atribuição prévia por região/especialidade no backend). Por isso, "recusar" no app do parceiro é uma ação **somente local** — apenas fecha a tela de detalhes sem alterar o status no servidor. Chamar `PATCH .../status {status: "cancelled"}` cancelaria o chamado para todos os parceiros, o que não reflete a intenção de "este parceiro específico não quer este chamado".

### Filtro de especialidade client-side

O endpoint `GET /tickets?pending=true` retorna todos os chamados pendentes do sistema, sem filtro por especialidade. Em vez de alterar o contrato da API, o filtro foi implementado no app (`pending_screen.dart`), calculando dinamicamente as especialidades presentes na lista carregada e mantendo a seleção "sticky" entre atualizações — decisão que evita acoplar a UI a uma mudança de schema do backend nesta fase do projeto.

### Reconciliação completa no cache local do cliente

Durante esta sprint, identificou-se que o `TicketsRepository.syncAndList()` do app cliente (Sprint 3) apenas inseria/atualizava registros vindos do servidor no SQLite local, mas nunca removia um chamado que tivesse deixado de existir remotamente (por exemplo, removido diretamente no banco por um administrador). Corrigido para que cada sincronização **reconcilie** o cache: chamados já sincronizados (`is_synced = 1`) que não vêm mais na resposta do servidor são apagados localmente, preservando apenas os criados offline e ainda não enviados (`is_synced = 0`).

---

## 9. Dificuldades Encontradas e Soluções

| Dificuldade | Solução |
|---|---|
| Roteamento de `ticket.status_changed` para o **cliente correto** — o payload original não trazia `customerId` | Adicionado `customerId` ao payload publicado em `updateTicketStatus()`, permitindo que `ws.js` mantenha um `Map<userId, Set<socket>>` e direcione a mensagem |
| Conflito de porta `5672`/`15672` entre o RabbitMQ deste projeto e o de outro projeto rodando no mesmo host | Containers identificados via `docker ps`; o serviço concorrente foi pausado para liberar a porta durante os testes locais |
| `PATCH /auth/profile` e `/auth/password` recusavam qualquer requisição de parceiro (`FORBIDDEN`), herdado da Sprint 3 | Generalizado o serviço de autenticação para tratar os dois `program`s, com validação de campos específica para cada perfil |
| Garantir que a notificação fosse de fato assíncrona e não apenas "polling rápido" disfarçado | Validação ponta a ponta com um cliente WebSocket isolado (script Node com a lib `ws`), confirmando que a mensagem chega como *push* do servidor, sem qualquer requisição do cliente no meio |

---

## 10. Reflexão sobre os Padrões Estudados

**Event-Driven Architecture (EDA).** O sistema inteiro gira em torno de comandos (`*_requested`) e eventos de fato consumados (`ticket.created`, `ticket.status_changed`), separação que Richardson (2018) descreve como essencial para evitar que produtores e consumidores fiquem fortemente acoplados a uma sequência síncrona de chamadas. A Sprint 4 evidencia o valor prático disso: o app do parceiro nunca precisou de uma rota REST nova — ele simplesmente se tornou **mais um consumidor** de um evento que já existia desde a Sprint 2.

**Middleware Orientado a Mensagens (MOM).** O uso do RabbitMQ como *Topic Exchange* (Hohpe & Woolf, 2003) permitiu adicionar um novo "assinante" (o servidor WebSocket, dentro do próprio processo do backend) sem qualquer alteração no produtor do evento. Isso é exatamente o desacoplamento publish/subscribe que o padrão promete: o `tickets.service.js` não sabe, e não precisa saber, que existe um WebSocket repassando seus eventos para dispositivos móveis.

**Clean Architecture.** Tanto o backend (`routes → controller → service → store`) quanto os dois apps Flutter (`screens → repositories → remote/local`) seguem a separação de camadas defendida por Martin (2019): regras de negócio (validação de transições de status, decisão de quem pode aceitar um chamado) ficam em `tickets.service.js`, isoladas de Express e do driver do Postgres. Isso facilitou adicionar o app do parceiro reaproveitando toda a camada de serviço/banco sem tocar nela.

**REST + comunicação assíncrona como complementares.** A arquitetura final confirma a visão de Coulouris et al. (2011) de que sistemas distribuídos reais combinam comunicação direta (REST, para o cliente saber imediatamente que sua ação foi aceita) com comunicação indireta (MOM/WebSocket, para propagar efeitos a quem não fez a requisição original). Nenhum dos dois canais, isoladamente, resolveria o requisito de notificação assíncrona sem polling.

---

## 11. Vídeo de Demonstração (Screencast)

Vídeo de 3–5 minutos com os dois apps (cliente e parceiro) rodando simultaneamente em emuladores, cobrindo o fluxo completo descrito na Seção 5: `reports/videos/Sprint 4.mp4`.

---

## Referências

- HOHPE, Gregor; WOOLF, Bobby. *Enterprise Integration Patterns: designing, building, and deploying messaging solutions*. Boston: Addison-Wesley, 2003.
- RICHARDSON, Chris. *Microservices Patterns: with examples in Java*. Shelter Island: Manning, 2018.
- MARTIN, Robert C. *Arquitetura limpa: o guia do artesão para estrutura e design de software*. Rio de Janeiro: Alta Books, 2019.
- COULOURIS, George et al. *Distributed Systems: concepts and design*. 5. ed. Boston: Addison-Wesley, 2011.
- FIELDING, Roy T. *Architectural Styles and the Design of Network-based Software Architectures*. Tese de doutorado, University of California, Irvine, 2000.
