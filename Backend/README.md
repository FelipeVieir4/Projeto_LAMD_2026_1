# Backend

API do projeto em Node.js com Express.

## Como executar

1. Entre na pasta do backend:

```bash
cd Backend
```

2. Instale as dependências:

```bash
npm install
```

3. Inicie em modo desenvolvimento:

```bash
npm run dev
```

4. Ou rode em modo normal:

```bash
npm start
```

Por padrão, a API sobe em `http://localhost:3000`.

## Configuração de banco (Supabase/PostgreSQL)

1. Copie o arquivo de exemplo de variáveis:

```bash
cp .env.example .env
```

2. Preencha os valores de conexão no `.env`:

- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_SSL`

Ou use apenas:

- `DATABASE_URL` (formato PostgreSQL/Supabase)

3. Defina também a chave de administração:

- `ADMIN_API_KEY`

4. Execute o script SQL inicial no Supabase SQL Editor:

- `docs/sql/001_initial_schema.sql`

## Dependências usadas

- `express`: cria o servidor HTTP e organiza as rotas da API.
- `jsonwebtoken`: gera e valida tokens JWT para autenticação.
- `swagger-ui-express`: publica a documentação interativa da API em `/docs`.

## O que já está implementado

- `GET /health`: health check simples da API.
- `POST /auth/register`: cria conta de cliente ou parceiro.
- `POST /auth/login`: autentica a conta e retorna JWT.
- `GET /auth/me`: retorna os dados da conta autenticada.
- `GET /admin/specialties`: lista especialidades (admin).
- `POST /admin/specialties`: cria especialidade (admin).
- `PUT /admin/specialties/:id`: atualiza especialidade (admin).
- `DELETE /admin/specialties/:id`: remove especialidade (admin).
- Swagger em `/docs` com a documentação inicial dos endpoints.

## Colecao de testes (Sprint 1)

- Postman: `docs/tests/LAMD_2026_1.postman_collection.json`
- Guia rapido: `docs/tests/README.md`

## Como a autenticação funciona

- O frontend envia `program` para informar se a conta é `customer` ou `partner`.
- O backend aceita também os aliases `cliente` e `parceiro`.
- O token JWT carrega o tipo da conta, então os dois apps conseguem identificar o perfil logado.

Para as rotas administrativas de especialidades, além do JWT, é obrigatório enviar:

- Header `x-admin-key` com o valor configurado em `ADMIN_API_KEY`.

## Estrutura de dados para cadastro

Endpoint de cadastro:

- `POST /auth/register`

Regras gerais:

- `email` deve ser válido.
- `password` deve ter pelo menos 8 caracteres.
- `program` aceita `customer` ou `partner` (também aceita `cliente` e `parceiro`).

### Customer (cliente)

Campos obrigatórios:

- `program`: `customer` (ou `cliente`)
- `name`: nome do cliente
- `email`
- `password`

Campos opcionais:

- `phone`

Exemplo de payload:

```json
{
	"program": "customer",
	"name": "Maria Silva",
	"email": "maria@exemplo.com",
	"password": "SenhaForte123",
	"phone": "+55 11 99999-9999"
}
```

### Partner (parceiro)

Campos obrigatórios:

- `program`: `partner` (ou `parceiro`)
- `companyName`: nome da empresa/prestador
- `document`: CPF/CNPJ
- `email`
- `password`

Campos opcionais:

- `phone`
- `bio`
- `specialties`: pode ser array de strings ou string separada por vírgula

Exemplo de payload (criar conta de parceiro):

```json
{
	"program": "partner",
	"companyName": "Soluções Silva LTDA",
	"document": "12.345.678/0001-90",
	"email": "parceiro@exemplo.com",
	"password": "SenhaForte123",
	"phone": "+55 11 98888-7777",
	"bio": "Atendimento elétrico e hidráulico.",
	"specialties": ["elétrica", "hidráulica"]
}
```

Exemplo de payload equivalente para `specialties` em string:

```json
{
	"program": "partner",
	"companyName": "Soluções Silva LTDA",
	"document": "12.345.678/0001-90",
	"email": "parceiro@exemplo.com",
	"password": "SenhaForte123",
	"specialties": "elétrica, hidráulica"
}
```

Exemplo resumido de resposta de sucesso (`201`):

```json
{
	"user": {
		"id": "uuid",
		"program": "partner",
		"email": "parceiro@exemplo.com",
		"phone": "+55 11 98888-7777",
		"status": "pending",
		"createdAt": "2026-05-10T00:00:00.000Z",
		"updatedAt": "2026-05-10T00:00:00.000Z",
		"document": "12.345.678/0001-90",
		"companyName": "Soluções Silva LTDA",
		"bio": "Atendimento elétrico e hidráulico.",
		"specialties": ["elétrica", "hidráulica"],
		"isActive": true
	},
	"token": "<jwt>",
	"tokenType": "Bearer",
	"expiresIn": "1d"
}
```

## Estrutura atual

- `src/app.js`: configura o Express.
- `src/server.js`: inicia o servidor.
- `src/routes/index.js`: centraliza o registro das rotas.
- `src/modules/auth`: contém registro, login e validação do JWT com persistência em PostgreSQL.
- `src/modules/health`: contém o health check.
- `src/config/swagger.js`: documentação OpenAPI inicial.

## Observação

O endpoint `GET /health` retorna também o status do banco em `database` (`ok` ou `unavailable`).