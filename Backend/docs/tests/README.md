# Testes Da API

Esta pasta contem a colecao de testes para Postman.

## Arquivos

- LAMD_2026_1.postman_collection.json

## Como usar no Postman

1. Importe o arquivo LAMD_2026_1.postman_collection.json.
2. Edite a variavel `adminApiKey` com o mesmo valor de ADMIN_API_KEY do backend.
3. Confirme que `baseUrl` aponta para a API local (padrao: http://localhost:3000).
4. Rode os requests na ordem abaixo:
   - Health
   - Auth/register customer
   - Auth/register partner
   - Auth/login customer
   - Auth/login partner
   - Auth/me customer
   - Admin/Specialties (GET, POST, PUT, DELETE)

## Observacoes

- A colecao salva automaticamente os tokens de customer e partner.
- A colecao salva automaticamente o `specialtyId` criado no POST para reutilizar no PUT/DELETE.
- Se register retornar conflito (409), ajuste os emails nas variaveis da colecao e rode novamente.
