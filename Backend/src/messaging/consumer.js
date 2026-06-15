import { createConsumerChannel, EXCHANGE_NAME } from '../config/rabbitmq.js';
import { Events } from './publisher.js';
import { processTicketCreationRequest, processTicketStatusChangeRequest } from '../modules/tickets/tickets.service.js';

//Filas que eu criei. Cada fila tem um nome, uma chave de roteamento (routingKey) que corresponde ao evento que ela consome, e um handler que processa as mensagens recebidas.
const QUEUES = [
  {
    name: 'ticket_creation_queue',
    routingKey: Events.TICKET_CREATION_REQUESTED,
    handler: handleTicketCreationRequested
  },
  {
    name: 'ticket_created_queue',
    routingKey: Events.TICKET_CREATED,
    handler: handleTicketCreated
  },
  {
    name: 'ticket_status_change_queue',
    routingKey: Events.TICKET_STATUS_CHANGE_REQUESTED,
    handler: handleTicketStatusChangeRequested
  },
  {
    name: 'ticket_status_changed_queue',
    routingKey: Events.TICKET_STATUS_CHANGED,
    handler: handleTicketStatusChanged
  }
];

// Chama o service para criar o ticket no banco de dados e depois publica um evento de "ticket criado" para notificar outros serviços ou componentes do sistema sobre a nova criação. O log detalhado inclui o ID do ticket, especialidade e cliente para facilitar o monitoramento e depuração.
async function handleTicketCreationRequested(payload) {
  const ticket = await processTicketCreationRequest(payload);

  console.log(
    `[MOM][WORKER][ticket.creation_requested] ` +
    `Chamado #${ticket.id} persistido no banco | ` +
    `Especialidade: "${ticket.specialty}" | ` +
    `Cliente: ${ticket.customerId}`
  );
}

async function handleTicketStatusChangeRequested(payload) {
  const ticket = await processTicketStatusChangeRequest(payload);

  console.log(
    `[MOM][WORKER][ticket.status_change_requested] ` +
    `Chamado #${ticket.id} atualizado no banco | ` +
    `Novo status: "${ticket.status}" | ` +
    `Parceiro: ${ticket.partnerId ?? 'null'}`
  );
}


function handleTicketCreated(payload) {
  // Log de criação de novo ticket com detalhes: ID, especialidade, cliente e título
  console.log(
    `[MOM][CONSUME][ticket.created] ` +
    `Novo chamado #${payload.ticketId} criado | ` +
    `Especialidade: "${payload.specialty}" | ` +
    `Cliente: ${payload.customerId} | ` +
    `Título: "${payload.title}"`
  );
}

function handleTicketStatusChanged(payload) {
  // Log de mudança de status de ticket com informações de transição e responsável
  console.log(
    `[MOM][CONSUME][ticket.status_changed] ` +
    `Chamado #${payload.ticketId} | ` +
    `Status: ${payload.previousStatus} → ${payload.newStatus} | ` +
    `Atualizado por: ${payload.updatedBy} (${payload.updatedByProgram})`
  );
}

export async function startConsumers() {
  const channel = await createConsumerChannel();
  channel.prefetch(1);

  for (const { name, routingKey, handler } of QUEUES) {
    await channel.assertQueue(name, { durable: true });
    await channel.bindQueue(name, EXCHANGE_NAME, routingKey);

    channel.consume(name, async (msg) => {
      if (!msg) return;

      try {
        const payload = JSON.parse(msg.content.toString());
        await handler(payload);
        channel.ack(msg);
      } catch (err) {
        console.error(`[MOM][CONSUME ERROR] ${routingKey}:`, err.message);
        channel.nack(msg, false, routingKey === Events.TICKET_CREATION_REQUESTED);
      }
    });

    console.log(`[MOM] Consumer registrado: queue="${name}" routingKey="${routingKey}"`);
  }
}
