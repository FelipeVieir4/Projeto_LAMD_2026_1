import amqplib from 'amqplib';

const RABBITMQ_URL = process.env.RABBITMQ_URL ?? 'amqp://guest:guest@localhost:5672';
export const EXCHANGE_NAME = 'chamados';
const EXCHANGE_TYPE = 'topic';

let _connection = null;
let _publisherChannel = null;

async function connect() {
  const conn = await amqplib.connect(RABBITMQ_URL);

  conn.on('close', () => {
    console.warn('[RabbitMQ] Conexão encerrada.');
    _connection = null;
    _publisherChannel = null;
  });

  conn.on('error', (err) => {
    console.error('[RabbitMQ] Erro na conexão:', err.message);
    _connection = null;
    _publisherChannel = null;
  });

  console.log('[RabbitMQ] Conectado com sucesso.');
  return conn;
}

export async function getConnection() {
  if (!_connection) {
    _connection = await connect();
  }
  return _connection;
}

export async function getPublisherChannel() {
  if (!_publisherChannel) {
    const conn = await getConnection();
    _publisherChannel = await conn.createChannel();
    await _publisherChannel.assertExchange(EXCHANGE_NAME, EXCHANGE_TYPE, { durable: true });
  }
  return _publisherChannel;
}

export async function createConsumerChannel() {
  const conn = await getConnection();
  const channel = await conn.createChannel();
  await channel.assertExchange(EXCHANGE_NAME, EXCHANGE_TYPE, { durable: true });
  return channel;
}

export async function checkRabbitConnection() {
  try {
    const conn = await getConnection();
    // Se a conexão existir e não estiver fechada, consideramos OK
    if (!conn) return false;
    // amqplib Connection possui 'connection' object with 'closed' flag em algumas versões;
    // trataremos qualquer erro de operação como indisponível
    return true;
  } catch (err) {
    return false;
  }
}
