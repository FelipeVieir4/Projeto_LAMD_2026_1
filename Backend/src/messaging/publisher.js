// Este módulo fornece utilitários para publicar eventos no RabbitMQ.
// - Define os tipos de evento em `Events`.
// - exporta `publishEvent(routingKey, payload)` que serializa o payload,
//   anexa metadados de publicação (evento e timestamp) e publica a mensagem
//   no exchange configurado, registrando logs de sucesso/erro.
import { getPublisherChannel, EXCHANGE_NAME } from '../config/rabbitmq.js';

export const Events = {
  TICKET_CREATION_REQUESTED: 'ticket.creation_requested',
  TICKET_CREATED: 'ticket.created',
  TICKET_STATUS_CHANGED: 'ticket.status_changed'
};

/**
 * Publica um evento no RabbitMQ.
 * @param {string} routingKey - Chave de roteamento que determina para qual fila a mensagem será entregue.
 *                             É usada pelo exchange para rotear a mensagem para as filas apropriadas.
 * @param {Object} payload - Dados da mensagem a ser publicada. Será convertido em JSON e incluído
 *                          junto com metadados (evento e timestamp) na mensagem final.
 */
export async function publishEvent(routingKey, payload) {
  try {
    const channel = await getPublisherChannel();
    const message = Buffer.from(JSON.stringify({
      ...payload,
      _meta: {
        event: routingKey,
        publishedAt: new Date().toISOString()
      }
    }));

    channel.publish(EXCHANGE_NAME, routingKey, message, {
      persistent: true, //salvat tbm em disco para não depender só da memória.
      contentType: 'application/json'
    });

    console.log(`[MOM][PUBLISH] ${routingKey}`, JSON.stringify(payload));
  } catch (err) {
    console.error(`[MOM][PUBLISH ERROR] ${routingKey}:`, err.message);
    throw err;
  }
}
