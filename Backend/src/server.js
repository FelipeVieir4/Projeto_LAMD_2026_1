import 'dotenv/config';
import app from './app.js';
import { startConsumers } from './messaging/consumer.js';

const PORT = process.env.PORT || 3000;
const MOM_RETRIES = 10;
const MOM_RETRY_DELAY_MS = 3000;

async function initConsumers() {
  for (let attempt = 1; attempt <= MOM_RETRIES; attempt++) {
    try {
      await startConsumers();
      console.log('[MOM] Consumers iniciados com sucesso.');
      return;
    } catch (err) {
      if (attempt < MOM_RETRIES) {
        console.warn(`[MOM] Tentativa ${attempt}/${MOM_RETRIES} falhou: ${err.message}. Aguardando ${MOM_RETRY_DELAY_MS / 1000}s...`);
        await new Promise((r) => setTimeout(r, MOM_RETRY_DELAY_MS));
      } else {
        console.warn('[MOM] Consumers não iniciados após todas as tentativas:', err.message);
      }
    }
  }
}

app.listen(PORT, async () => {
  console.log(`Backend running on port ${PORT}`);
  await initConsumers();
});