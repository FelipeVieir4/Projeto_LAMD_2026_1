import { getPublisherChannel, EXCHANGE_NAME } from '../config/rabbitmq.js';

export const Events = {
  TICKET_CREATED: 'ticket.created',
  TICKET_STATUS_CHANGED: 'ticket.status_changed'
};

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
      persistent: true,
      contentType: 'application/json'
    });

    console.log(`[MOM][PUBLISH] ${routingKey}`, JSON.stringify(payload));
  } catch (err) {
    console.error(`[MOM][PUBLISH ERROR] ${routingKey}:`, err.message);
  }
}
