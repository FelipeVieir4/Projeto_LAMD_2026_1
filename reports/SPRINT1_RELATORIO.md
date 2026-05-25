# Sprint 1 – Infraestrutura, Autenticação e Catálogo de Especialidades

**Disciplina:** LDAMD – Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Aluno:** Luiz Felipe Vieira  
**Período:** 1º Semestre 2026

---

## 1. Domínio do Projeto

O sistema é uma **plataforma de chamados técnicos domiciliares**. Dois perfis de usuário interagem pela plataforma:

| Perfil | Papel |
|--------|-------|
| **Cliente** (`customer`) | Abre chamados informando especialidade, endereço e descrição do problema |
| **Parceiro** (`partner`) | Recebe chamados, aceita ou recusa, executa e conclui o atendimento |

Exemplos de especialidades: elétrica, hidráulica, pintura, marcenaria.

---

## 2. Objetivos da Sprint 1

- Definir e documentar a arquitetura inicial do sistema
- Configurar o banco de dados (PostgreSQL via Supabase)
- Implementar autenticação com JWT para os dois perfis de usuário
- Criar o catálogo de especialidades com rotas administrativas protegidas
- Publicar a documentação interativa da API via Swagger/OpenAPI

---

## 3. Tecnologias Utilizadas

| Tecnologia | Papel |
|------------|-------|
| **Node.js + Express** | Servidor HTTP e roteamento |
| **PostgreSQL (Supabase)** | Banco de dados relacional |
| **JWT (jsonwebtoken)** | Autenticação sem estado |
| **PBKDF2 (crypto nativo)** | Hash seguro de senhas |
| **swagger-ui-express** | Documentação interativa da API |
| **dotenv** | Gerenciamento de variáveis de ambiente |

---

## 4. Endpoints Implementados

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| `GET` | `/api/v1/health` | — | Health check (banco + API) |
| `POST` | `/api/v1/auth/register` | — | Cadastro de cliente ou parceiro |
| `POST` | `/api/v1/auth/login` | — | Login → retorna JWT |
| `GET` | `/api/v1/auth/me` | JWT | Retorna dados da conta autenticada |
| `GET` | `/api/v1/admin/specialties` | JWT + admin-key | Lista especialidades |
| `POST` | `/api/v1/admin/specialties` | JWT + admin-key | Cria especialidade |
| `PUT` | `/api/v1/admin/specialties/:id` | JWT + admin-key | Atualiza especialidade |
| `DELETE` | `/api/v1/admin/specialties/:id` | JWT + admin-key | Remove especialidade |

---

## 5. Autenticação e Perfis

### Cadastro de cliente (`customer`)

```json
{
  "program": "customer",
  "name": "Maria Silva",
  "email": "maria@exemplo.com",
  "password": "SenhaForte123",
  "phone": "+55 11 99999-9999"
}
```

### Cadastro de parceiro (`partner`)

```json
{
  "program": "partner",
  "companyName": "Soluções Silva LTDA",
  "document": "12.345.678/0001-90",
  "email": "parceiro@exemplo.com",
  "password": "SenhaForte123",
  "specialties": ["elétrica", "hidráulica"]
}
```

### Resposta de sucesso (`201`)

```json
{
  "user": {
    "id": "uuid",
    "program": "customer",
    "email": "maria@exemplo.com",
    "status": "active",
    "createdAt": "2026-05-01T00:00:00.000Z"
  },
  "token": "<jwt>",
  "tokenType": "Bearer",
  "expiresIn": "1d"
}
```

### Estratégia de segurança

- Senhas armazenadas com **PBKDF2-SHA512** (120 000 iterações, salt aleatório)
- Tokens JWT com expiração de 24 horas
- Rotas administrativas requerem JWT **e** header `x-admin-key`

---

## 6. Schema do Banco de Dados

```sql
-- users: armazena clientes e parceiros
CREATE TABLE users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program     TEXT NOT NULL CHECK (program IN ('customer', 'partner')),
  email       TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  salt        TEXT NOT NULL,
  status      TEXT DEFAULT 'active',
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- specialties: catálogo de serviços disponíveis
CREATE TABLE specialties (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT UNIQUE NOT NULL,
  description TEXT,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
```

Script completo: [`Backend/docs/sql/001_initial_schema.sql`](../Backend/docs/sql/001_initial_schema.sql)

---

## 7. Arquitetura de Módulos

O backend segue uma estrutura modular onde cada domínio tem suas próprias camadas:

```
src/modules/<dominio>/
  ├── <dominio>.routes.js      # rotas Express
  ├── <dominio>.controller.js  # handlers HTTP (req/res)
  ├── <dominio>.service.js     # regras de negócio
  └── <dominio>.store.js       # queries no banco (pg)
```

Módulos implementados na Sprint 1:
- `auth` — registro, login, JWT
- `admin/specialties` — CRUD de especialidades
- `health` — health check

---

## 8. Health Check

`GET /api/v1/health` retorna o status da API e do banco de dados:

```json
{
  "status": "ok",
  "database": "ok",
  "timestamp": "2026-05-01T12:00:00.000Z"
}
```

Se o banco estiver inacessível, `database` retorna `"unavailable"` (sem derrubar a API).

---

## 9. Como Executar

```bash
# 1. Configure o ambiente
cp Backend/.env.example Backend/.env
# Preencha DATABASE_URL, JWT_SECRET e ADMIN_API_KEY no .env

# 2. Instale dependências e suba
cd Backend
npm install
npm run dev
```

A API estará disponível em `http://localhost:3000/api/v1`.  
Documentação Swagger: `http://localhost:3000/api/v1/docs`.

---

## 10. Estrutura de Arquivos (Sprint 1)

```
Projeto_LAMD_2026_1/
├── docker-compose.yml
├── README.md
└── Backend/
    ├── .env.example
    ├── package.json
    └── src/
        ├── app.js
        ├── server.js
        ├── routes/
        │   └── index.js
        ├── config/
        │   ├── cors.js
        │   ├── database.js
        │   └── swagger.js
        └── modules/
            ├── auth/
            │   ├── auth.routes.js
            │   ├── auth.controller.js
            │   ├── auth.middleware.js
            │   ├── auth.service.js
            │   └── auth.store.js
            ├── health/
            │   ├── health.routes.js
            │   └── health.controller.js
            └── admin/specialties/
                ├── specialties.routes.js
                ├── specialties.controller.js
                ├── specialties.service.js
                └── specialties.store.js
```

---

## Referências

- FIELDING, Roy T. *Architectural Styles and the Design of Network-based Software Architectures*. Dissertação de doutorado, UC Irvine, 2000.
- JONES, Michael B. et al. *JSON Web Token (JWT)*. RFC 7519. IETF, 2015.
- Documentação oficial do Node.js, Express e PostgreSQL.
