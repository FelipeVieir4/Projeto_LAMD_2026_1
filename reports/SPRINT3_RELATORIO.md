# Sprint 3 – App Móvel Flutter com Arquitetura Offline-First

**Disciplina:** LDAMD – Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Aluno:** Luiz Felipe Vieira  
**Período:** 1º Semestre 2026  
**Entrega:** 15/06/2026

---

## 1. Objetivo da Sprint

Desenvolver o **app móvel Flutter** para o perfil **cliente**, integrado à API REST do backend construído nas sprints anteriores. O app opera em modo **offline-first**: o usuário pode abrir chamados sem conexão, e a sincronização ocorre automaticamente quando a rede volta.

---

## 2. O que foi construído

### 2.1 App Flutter (`App/`)

| Camada | Arquivos | Responsabilidade |
|---|---|---|
| **Data / Remote** | `api_client.dart` | Wrapper HTTP sobre `http`, injeta JWT no header |
| **Data / Local** | `local_database.dart` | SQLite via `sqflite` — tabelas `tickets` e `specialties` |
| **Repositórios** | `auth_repository.dart` | JWT em `shared_preferences`, persistência de nome/id do usuário |
| | `tickets_repository.dart` | Offline-first: grava local antes de enviar; sincroniza pendentes |
| | `specialties_repository.dart` | Cache local das especialidades; fallback se offline |
| **Modelos** | `ticket.dart`, `specialty.dart`, `user.dart` | Serialização JSON ↔ mapa SQLite |
| **Telas** | `splash_screen.dart` | Verifica token salvo e redireciona |
| | `login_screen.dart` | Autenticação com JWT |
| | `register_screen.dart` | Cadastro de cliente |
| | `tickets_screen.dart` | Lista chamados + banners de sync + polling automático |
| | `create_ticket_screen.dart` | Formulário de abertura de chamado com seletor de especialidade |
| **Widgets** | `ticket_card.dart`, `status_chip.dart` | Cards da lista e chips de status coloridos |

### 2.2 Endpoint novo no Backend

| Método | Rota | Função |
|---|---|---|
| `GET` | `/specialties` | Lista especialidades ativas — consumido pelo app para popular o seletor |

Módulo adicionado em `Backend/src/modules/specialties/` (`routes`, `controller`, `service`).

---

## 3. Arquitetura Offline-First

O ponto central da Sprint 3 é a estratégia **local-first com sincronização posterior**:

```
┌─────────────────────────────────────────────────────────────────┐
│  App Flutter                                                    │
│                                                                 │
│  CreateTicket                                                   │
│    1. Gera UUID local (uuid v4)                                 │
│    2. Salva no SQLite  →  is_synced = 0  (imediato)            │
│    3. Tenta POST /tickets                                       │
│       ├─ Sucesso → is_synced = 1                               │
│       └─ Falha (offline) → permanece is_synced = 0             │
│                                                                 │
│  TicketsScreen                                                  │
│    a. syncPending()  — reenvia todos os is_synced = 0           │
│    b. syncAndList()  — busca lista remota, atualiza SQLite      │
│    c. Polling a cada 3 s (máx. 10 tentativas) se há pendentes  │
│    d. Banner azul "Aguardando confirmação" durante polling      │
│    e. Banner amarelo "Não sincronizado" se polling esgotou     │
│    f. Atualiza ao voltar ao foreground (AppLifecycleState)     │
└─────────────────────────────────────────────────────────────────┘
```

**Fluxo de especialidades (cache):**
1. App abre `CreateTicketScreen` → `SpecialtiesRepository.list()`
2. Tenta `GET /specialties`; em caso de sucesso, atualiza tabela `specialties` no SQLite
3. Se offline, retorna lista cacheada — o formulário ainda funciona

---

## 4. Dependências Flutter

| Pacote | Versão | Uso |
|---|---|---|
| `sqflite` | ^2.3.3+1 | Banco SQLite local (offline-first) |
| `shared_preferences` | ^2.3.0 | Persistência do JWT e dados do usuário |
| `http` | ^1.2.0 | Requisições REST ao backend |
| `connectivity_plus` | ^6.1.4 | Detecção de estado de rede |
| `uuid` | ^4.5.0 | Geração de IDs locais antes de sincronizar |
| `intl` | ^0.20.2 | Formatação de datas |

---

## 5. Telas do App

### Splash Screen
- Verifica `shared_preferences` para token válido
- Redireciona para `TicketsScreen` (logado) ou `LoginScreen` (não logado)

### Login / Registro
- `POST /auth/login` e `POST /auth/register` (perfil `customer`)
- Salva JWT, nome e ID do usuário localmente

### Lista de Chamados (`TicketsScreen`)
- Exibe todos os chamados do cliente (locais + sincronizados)
- Indicador visual por status: `TicketCard` com `StatusChip` colorido
- **Pull-to-refresh** manual
- **Banner azul** durante polling de sincronização
- **Banner amarelo** quando há tickets não sincronizados após esgotamento do polling
- Reinicia sincronização ao retornar ao foreground

### Criar Chamado (`CreateTicketScreen`)
- Seletor de especialidade populado via `GET /specialties` (com fallback offline)
- Campos: título, descrição (opcional), endereço (opcional)
- Submissão: salva local primeiro, envia para API, exibe feedback e volta para a lista

---

## 6. Estrutura de Arquivos (Sprint 3)

```
Projeto_LAMD_2026_1/
├── reports/
│   └── SPRINT3_RELATORIO.md            ← Este documento
├── App/                                ← Novo — app Flutter
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── constants.dart          ← Base URL da API
│   │   │   └── theme.dart              ← Material theme
│   │   ├── data/
│   │   │   ├── local/
│   │   │   │   └── local_database.dart ← SQLite (sqflite)
│   │   │   ├── remote/
│   │   │   │   └── api_client.dart     ← HTTP client com JWT
│   │   │   └── repositories/
│   │   │       ├── auth_repository.dart
│   │   │       ├── tickets_repository.dart
│   │   │       └── specialties_repository.dart
│   │   ├── models/
│   │   │   ├── ticket.dart
│   │   │   ├── specialty.dart
│   │   │   └── user.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── tickets_screen.dart
│   │   │   └── create_ticket_screen.dart
│   │   └── widgets/
│   │       ├── ticket_card.dart
│   │       └── status_chip.dart
│   └── android/ ios/ test/             ← Gerado pelo Flutter SDK
└── Backend/
    └── src/modules/specialties/        ← Novo endpoint GET /specialties
        ├── specialties.routes.js
        ├── specialties.controller.js
        └── specialties.service.js
```

---

## 7. Como Executar

### Backend
```bash
# Na raiz do projeto
docker compose up --build
```
API disponível em `http://localhost:3000` | Swagger em `http://localhost:3000/docs`

### App Flutter
```bash
cd App
flutter pub get
flutter run          # com emulador/dispositivo conectado
```

> `App/lib/core/constants.dart` define a `baseUrl`. Para emulador Android use `http://10.0.2.2:3000`; para dispositivo físico, use o IP da máquina na rede local.

---

## 8. Decisões de Design

### Por que offline-first e não online-only?

O requisito de uma aplicação **móvel distribuída** impõe lidar com conectividade intermitente. Salvar localmente antes de enviar garante que o usuário **nunca perde um chamado** por falha de rede — o dado existe no dispositivo e será enviado assim que a conexão retornar. Isso segue o princípio de **eventual consistency** em sistemas distribuídos (Coulouris et al., 2011).

### Por que UUID gerado no cliente?

O ID é gerado no app antes do envio (`uuid v4`) para que o ticket possa ser referenciado localmente com a mesma chave que o servidor usará após a sincronização. Isso elimina o problema de ter um "ID provisório local" que precisaria ser substituído — o banco local e o servidor convergem para o mesmo registro.

### Polling vs. WebSocket para feedback de sync

WebSocket seria mais eficiente, mas adiciona complexidade de infraestrutura que está além do escopo desta sprint. O polling com limite de 10 tentativas (30 segundos) é uma solução pragmática e observável: o banner de status dá feedback visual claro ao usuário sem complicar a arquitetura.

---

## Referências

- COULOURIS, George et al. *Distributed Systems: concepts and design*. 5. ed. Boston: Addison-Wesley, 2011.
- HOHPE, Gregor; WOOLF, Bobby. *Enterprise Integration Patterns*. Boston: Addison-Wesley, 2003.
- Flutter Documentation. *sqflite package*. Disponível em: https://pub.dev/packages/sqflite
