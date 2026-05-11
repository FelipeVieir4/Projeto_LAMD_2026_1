# Projeto_LAMD_2026_1

App de atendimento de chamados com roteamento por região.

## Ideia do projeto

O sistema terá três partes iniciais:

- Backend: API, autenticação, regras de negócio, catálogo de serviços e distribuição dos chamados.
- App: aplicativo do cliente final para abrir tickets e acompanhar o atendimento.
- App_parceiro: aplicativo do prestador/técnico para receber notificações e aceitar chamados da sua região.

## Fluxo principal

1. O usuário abre um chamado informando CEP, bairro ou localização no mapa.
2. O backend identifica a região do ticket.
3. Técnicos parceiros associados a essa região recebem a notificação.
4. Um técnico aceita o chamado e inicia o atendimento.
5. O usuário acompanha o status até a conclusão.

## MVP sugerido

- Cadastro de usuário e parceiro.
- Login com perfis diferentes.
- Abertura de chamado com endereço, CEP ou geolocalização.
- Catálogo de serviços tabelados, por exemplo:
	- instalar espelho até 1m ou 2m
	- desentupir pia
	- desentupir vaso
	- instalação e pequenos reparos
- Associação de técnico por região.
- Notificação em tempo real para parceiros.
- Status do chamado: aberto, em análise, aceito, em andamento, concluído e cancelado.

## Estrutura inicial

- [Backend](Backend)
- [App](App)
- [App_parceiro](App_parceiro)

## Documentação técnica

- Diagramas de arquitetura e fluxo: [Backend/docs/diagrams.md](Backend/docs/diagrams.md)
- Schema de dados: [Backend/docs/database-schema.md](Backend/docs/database-schema.md)
- Script SQL inicial: [Backend/docs/sql/001_initial_schema.sql](Backend/docs/sql/001_initial_schema.sql)

