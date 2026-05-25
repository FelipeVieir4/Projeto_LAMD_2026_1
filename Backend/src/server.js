import 'dotenv/config';
import app from './app.js';
import { startConsumers } from './messaging/consumer.js';

const PORT = process.env.PORT || 3000;

app.listen(PORT, async () => {
  console.log(`Backend running on port ${PORT}`);

  try {
    await startConsumers();
    console.log('[MOM] Consumers iniciados com sucesso.');
  } catch (err) {
    console.warn('[MOM] Consumers não iniciados (RabbitMQ indisponível):', err.message);
    console.warn('[MOM] Suba o RabbitMQ com: docker compose up -d');
  }
});