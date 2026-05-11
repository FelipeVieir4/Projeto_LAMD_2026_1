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

## Dependências usadas

- `express`: cria o servidor HTTP e organiza as rotas da API.
- `jsonwebtoken`: gera e valida tokens JWT para autenticação.
- `swagger-ui-express`: publica a documentação interativa da API em `/docs`.

## O que já está implementado

- `GET /health`: health check simples da API.
- `POST /auth/register`: cria conta de cliente ou parceiro.
- `POST /auth/login`: autentica a conta e retorna JWT.
- `GET /auth/me`: retorna os dados da conta autenticada.
- Swagger em `/docs` com a documentação inicial dos endpoints.

## Como a autenticação funciona

- O frontend envia `program` para informar se a conta é `customer` ou `partner`.
- O backend aceita também os aliases `cliente` e `parceiro`.
- O token JWT carrega o tipo da conta, então os dois apps conseguem identificar o perfil logado.

## Estrutura atual

- `src/app.js`: configura o Express.
- `src/server.js`: inicia o servidor.
- `src/routes/index.js`: centraliza o registro das rotas.
- `src/modules/auth`: contém registro, login, validação do JWT e armazenamento em memória.
- `src/modules/health`: contém o health check.
- `src/config/swagger.js`: documentação OpenAPI inicial.

## Observação

Hoje o fluxo de autenticação usa armazenamento em memória. O próximo passo é ligar isso ao banco real com as tabelas `customers` e `partners` descritas em `docs/database-schema.md`.