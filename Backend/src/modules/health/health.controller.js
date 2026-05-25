import { checkDatabaseConnection } from '../../config/database.js';
import { checkRabbitConnection } from '../../config/rabbitmq.js';

export async function healthCheck(request, response) {
  let database = 'unavailable';

  try {
    const dbConnected = await checkDatabaseConnection();
    database = dbConnected ? 'ok' : 'unavailable';
  } catch (error) {
    database = 'unavailable';
  }

  let rabbitmq = 'unavailable';
  try {
    const rabbitOk = await checkRabbitConnection();
    rabbitmq = rabbitOk ? 'ok' : 'unavailable';
  } catch (err) {
    rabbitmq = 'unavailable';
  }

  response.status(200).json({
    status: 'ok',
    database,
    rabbitmq,
    timestamp: new Date().toISOString()
  });
}