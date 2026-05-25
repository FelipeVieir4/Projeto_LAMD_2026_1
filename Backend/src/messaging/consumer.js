import { createConsumerChannel, EXCHANGE_NAME } from '../config/rabbitmq.js';
import { Events } from './publisher.js';

const QUEUES = [
  {
    name: 'ticket_created_queue',
    routingKey: Events.TICKET_CREATED,
    handler: handleTicketCreated
  },
  {
    name: 'ticket_status_changed_queue',
    routingKey: Events.TICKET_STATUS_CHANGED,
    handler: handleTicketStatusChanged
  }
];

function handleTicketCreated(payload) {
  console.log(
    `[MOM][CONSUME][ticket.created] ` +
    `Novo chamado #${payload.ticketId} criado | ` +
    `Especialidade: "${payload.specialty}" | ` +
    `Cliente: ${payload.customerId} | ` +
    `Título: "${payload.title}"`
  );
}

function handleTicketStatusChanged(payload) {
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

    channel.consume(name, (msg) => {
      if (!msg) return;

      try {
        const payload = JSON.parse(msg.content.toString());
        handler(payload);
        channel.ack(msg);
      } catch (err) {
        console.error(`[MOM][CONSUME ERROR] ${routingKey}:`, err.message);
        channel.nack(msg, false, false);
      }
    });

    console.log(`[MOM] Consumer registrado: queue="${name}" routingKey="${routingKey}"`);
  }
}
