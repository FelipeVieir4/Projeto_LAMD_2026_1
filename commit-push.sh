#!/bin/bash

# Script para fazer commit e push das mudanças do Postman

git add -A

git commit -m "Automatizar coleção Postman e alinhar variável ADMIN_API_KEY

- Adicionar pré-requisição automática na coleção que gera emails com timestamp
- Salvar dados (tokens, specialtyId) automaticamente entre requests
- Limpar estado ao final para permitir novas execuções
- Renomear variável de ambiente de ADMIN_KEY para ADMIN_API_KEY
- Atualizar guia de testes para refletir automação completa"

git push origin main

echo "✅ Commit e push concluídos com sucesso!"
