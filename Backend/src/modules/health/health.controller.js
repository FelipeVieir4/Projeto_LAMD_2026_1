import { checkDatabaseConnection } from '../../config/database.js';

export async function healthCheck(request, response) {
  let database = 'unavailable';

  try {
    const dbConnected = await checkDatabaseConnection();
    database = dbConnected ? 'ok' : 'unavailable';
  } catch (error) {
    database = 'unavailable';
  }

  response.status(200).json({
    status: 'ok',
    database,
    timestamp: new Date().toISOString()
  });
}