# Testes Da API

Esta pasta contem a colecao de testes para Postman.

## Arquivos

- LAMD_2026_1.postman_collection.json

## Como usar no Postman

1. Importe o arquivo LAMD_2026_1.postman_collection.json.
2. Abra a collection e clique em Run.
3. Rode os requests na ordem abaixo:
   - Health
   - Auth/register customer
   - Auth/register partner
   - Auth/login customer
   - Auth/login partner
   - Auth/me customer
   - Admin/Specialties (GET, POST, PUT, DELETE)

## Observacoes

- A colecao preenche automaticamente `baseUrl`, `customerEmail`, `partnerEmail`, `defaultPassword` e `adminApiKey`.
- A colecao salva automaticamente os tokens de customer e partner.
- A colecao salva automaticamente o `specialtyId` criado no POST para reutilizar no PUT/DELETE.
