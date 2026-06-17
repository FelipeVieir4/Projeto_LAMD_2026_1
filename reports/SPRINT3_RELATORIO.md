# Sprint 3 – App Móvel Flutter com Arquitetura Offline-First, Navegação e Gestão de Perfil

**Disciplina:** LDAMD – Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Aluno:** Luiz Felipe Vieira  
**Período:** 1º Semestre 2026  
**Entrega:** 15/06/2026

---

## 1. Objetivo da Sprint

Desenvolver o **app móvel Flutter** para o perfil **cliente** (Fixit LAMD), integrado à API REST do backend construído nas sprints anteriores. A entrega abrange:

- Arquitetura **offline-first** com SQLite local e sincronização automática
- **8 telas funcionais** com bottom navigation bar
- Redesign visual inspirado no design system **Fixit** (`#0054A8` / `#F0F3FA`)
- Gestão completa de perfil (edição de dados, troca de senha)
- Detalhamento e cancelamento de chamados
- Novos endpoints no backend (`GET /specialties`, `PATCH /auth/profile`, `PATCH /auth/password`)

---

## 2. O que foi construído

### 2.1 App Flutter (`App/`)

#### Telas

| Tela | Arquivo | Função |
|---|---|---|
| **Splash** | `splash_screen.dart` | Verifica token salvo → redireciona para Home ou Login |
| **Login** | `login_screen.dart` | Autenticação com JWT; exibe logo e nome Fixit LAMD |
| **Registro** | `register_screen.dart` | Cadastro de cliente (program=customer) |
| **Home** | `home_screen.dart` | Dashboard: saudação por hora, 3 cards de stats, últimos 3 chamados |
| **Chamados** | `tickets_screen.dart` | Lista completa com filtros em chip + banners de sync |
| **Criar Chamado** | `create_ticket_screen.dart` | Formulário com seletor de especialidade (offline-first) |
| **Detalhes** | `ticket_detail_screen.dart` | Exibe ticket completo; permite cancelar se status for `pending` ou `accepted` |
| **Perfil** | `profile_screen.dart` | Exibe/edita nome e telefone; altera senha; logout |

#### Repositórios

| Repositório | Arquivo | Responsabilidades |
|---|---|---|
| **AuthRepository** | `auth_repository.dart` | Login, registro, JWT em `SharedPreferences`, `fetchMe`, `updateProfile`, `changePassword` |
| **TicketsRepository** | `tickets_repository.dart` | Offline-first: UUID local, SQLite, sync polling, `cancelTicket` |
| **SpecialtiesRepository** | `specialties_repository.dart` | Busca `GET /specialties`, cache em SQLite, fallback offline |

#### Widgets

| Widget | Arquivo | Descrição |
|---|---|---|
| **AppBottomNav** | `widgets/app_bottom_nav.dart` | Barra de navegação inferior compartilhada (3 abas) via rotas nomeadas |
| **TicketCard** | `widgets/ticket_card.dart` | Card com badge de especialidade colorida e barra de progresso por status |
| **StatusChip** | `widgets/status_chip.dart` | Chip colorido mapeado para cada `TicketStatus` |

#### Camada de dados

| Arquivo | Função |
|---|---|
| `data/local/local_database.dart` | SQLite (`sqflite`) — tabelas `tickets` e `specialties` |
| `data/remote/api_client.dart` | Wrapper HTTP com injeção automática de JWT; métodos GET, POST, PATCH, DELETE |
| `core/theme.dart` | Material 3 com cor primária `#0054A8`, fundo `#F0F3FA` |
| `core/constants.dart` | `baseUrl`, chaves do `SharedPreferences` |
| `main.dart` | `onGenerateRoute` com rotas nomeadas; transição zero entre abas |

### 2.2 Novos endpoints no Backend

| Método | Rota | Auth | Função |
|---|---|---|---|
| `GET` | `/api/v1/specialties` | — | Lista especialidades ativas; consumido pelo app no formulário de abertura |
| `PATCH` | `/api/v1/auth/profile` | JWT | Atualiza nome e telefone do cliente |
| `PATCH` | `/api/v1/auth/password` | JWT | Altera senha (requer senha atual para confirmação) |

Módulos adicionados/modificados: `Backend/src/modules/specialties/`, `auth.store.js`, `auth.service.js`, `auth.controller.js`, `auth.routes.js`.

---

## 3. Arquitetura Offline-First

O ponto central da Sprint 3 é a estratégia **local-first com sincronização posterior**:

```
┌────────────────────────────────────────────────────────────────────┐
│  App Flutter                                                       │
│                                                                    │
│  CreateTicketScreen                                                │
│    1. Gera UUID local (uuid v4)                                    │
│    2. Salva no SQLite  →  is_synced = 0  (imediato, sem rede)     │
│    3. Tenta POST /api/v1/tickets                                   │
│       ├─ Sucesso → is_synced = 1                                  │
│       └─ Falha (offline) → permanece is_synced = 0                │
│                                                                    │
│  TicketsScreen (ao abrir / ao voltar do background)               │
│    a. syncPending()   — reenvia todos os is_synced = 0            │
│    b. syncAndList()   — busca lista remota, atualiza SQLite        │
│    c. Polling a cada 3 s (máx. 10 tentativas) se há pendentes     │
│    d. Banner azul   "Aguardando confirmação" durante polling       │
│    e. Banner amarelo "Não sincronizado" se polling esgotou        │
│    f. Reinicia ao retornar ao foreground (AppLifecycleState)      │
└────────────────────────────────────────────────────────────────────┘
```

**Fluxo de especialidades (cache):**
1. App abre `CreateTicketScreen` → `SpecialtiesRepository.list()`
2. Tenta `GET /specialties`; em caso de sucesso, salva na tabela `specialties` local
3. Se offline, retorna lista cacheada — o formulário continua funcional

---

## 4. Dependências Flutter

| Pacote | Versão | Uso |
|---|---|---|
| `sqflite` | ^2.3.3+1 | Banco SQLite local |
| `shared_preferences` | ^2.3.0 | Persistência do JWT e dados do usuário |
| `http` | ^1.2.0 | Requisições REST ao backend |
| `connectivity_plus` | ^6.1.4 | Detecção de estado de rede |
| `uuid` | ^4.5.0 | Geração de IDs locais antes da sincronização |
| `intl` | ^0.20.2 | Formatação de datas |

---

## 5. Estrutura de arquivos (Sprint 3)

```
Projeto_LAMD_2026_1/
├── reports/
│   └── SPRINT3_RELATORIO.md
├── App/
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart                          ← onGenerateRoute, rotas nomeadas
│       ├── core/
│       │   ├── constants.dart                 ← base URL + chaves SharedPreferences
│       │   └── theme.dart                     ← #0054A8, #F0F3FA, Material 3
│       ├── data/
│       │   ├── local/local_database.dart      ← SQLite (sqflite)
│       │   ├── remote/api_client.dart         ← HTTP client + JWT
│       │   └── repositories/
│       │       ├── auth_repository.dart       ← login, register, updateProfile, changePassword
│       │       ├── tickets_repository.dart    ← offline-first, cancelTicket
│       │       └── specialties_repository.dart
│       ├── models/
│       │   ├── ticket.dart                    ← TicketStatus enum + is_synced
│       │   ├── specialty.dart
│       │   └── user.dart
│       ├── screens/
│       │   ├── splash_screen.dart
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   ├── home_screen.dart               ← novo: dashboard com stats
│       │   ├── tickets_screen.dart            ← filtros em chip + banners
│       │   ├── create_ticket_screen.dart
│       │   ├── ticket_detail_screen.dart      ← novo: detalhes + cancelar
│       │   └── profile_screen.dart            ← novo: editar perfil + trocar senha
│       └── widgets/
│           ├── app_bottom_nav.dart            ← novo: barra compartilhada
│           ├── ticket_card.dart               ← redesenhado: badge + progresso
│           └── status_chip.dart
└── Backend/
    └── src/modules/
        ├── specialties/                       ← novo: GET /specialties
        └── auth/                              ← novos: PATCH /profile, PATCH /password
```

---

## 6. Como executar

### Backend
```bash
# Na raiz do projeto
docker compose up --build
```
API: `http://localhost:3000/api/v1` | Swagger: `http://localhost:3000/api/v1/docs`

### App Flutter
```bash
cd App
flutter pub get
flutter run   # com emulador/dispositivo conectado
```

> `App/lib/core/constants.dart` define a `baseUrl`.  
> Emulador Android: `http://10.0.2.2:3000/api/v1`  
> Dispositivo físico: `http://<IP_DA_MÁQUINA>:3000/api/v1`

---

## 7. Decisões de design

### Offline-first: por que salvar antes de enviar?

O requisito de aplicação **móvel distribuída** implica lidar com conectividade intermitente. Salvar localmente antes de enviar garante que o usuário nunca perde um chamado por falha de rede — o dado existe no dispositivo e será enviado quando a conexão retornar. Isso segue o princípio de **eventual consistency** em sistemas distribuídos (Coulouris et al., 2011).

### UUID gerado no cliente

O ID é gerado no app antes do envio (`uuid v4`) para que o ticket possa ser referenciado localmente com a mesma chave que o servidor usará após a sincronização. Elimina o problema de IDs provisórios que precisariam ser substituídos após o sync.

### Polling vs. WebSocket para feedback de sync

WebSocket seria mais eficiente, mas adiciona complexidade de infraestrutura além do escopo da sprint. O polling com limite de 10 tentativas (30 segundos) é uma solução pragmática: o banner de status dá feedback visual claro sem complicar a arquitetura.

---

## Referências

- COULOURIS, George et al. *Distributed Systems: concepts and design*. 5. ed. Boston: Addison-Wesley, 2011.
- HOHPE, Gregor; WOOLF, Bobby. *Enterprise Integration Patterns*. Boston: Addison-Wesley, 2003.
- Flutter Documentation. *sqflite package*. Disponível em: https://pub.dev/packages/sqflite
- Flutter Documentation. *Navigation and routing*. Disponível em: https://docs.flutter.dev/ui/navigation
