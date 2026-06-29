// Ponte de tempo real entre o RabbitMQ e os apps móveis.
// Os consumers do MOM (src/messaging/consumer.js) chamam broadcastToPartners
// e broadcastToCustomer logo após processar um evento, empurrando a notificação
// via WebSocket para quem está conectado — sem polling contínuo do app.
import { WebSocketServer } from 'ws';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET ?? 'dev-secret-change-me';

const partnerSockets = new Set();
const customerSocketsByUserId = new Map();

function send(socket, event, payload) {
  if (socket.readyState !== socket.OPEN) return;
  socket.send(JSON.stringify({ event, payload }));
}

export function broadcastToPartners(event, payload) {
  for (const socket of partnerSockets) {
    send(socket, event, payload);
  }
  console.log(`[WS][BROADCAST→partners] ${event} (${partnerSockets.size} conectado(s))`);
}

export function broadcastToCustomer(customerId, event, payload) {
  const sockets = customerSocketsByUserId.get(customerId);
  if (!sockets || sockets.size === 0) return;
  for (const socket of sockets) {
    send(socket, event, payload);
  }
  console.log(`[WS][BROADCAST→customer:${customerId}] ${event}`);
}

function authenticate(request) {
  const url = new URL(request.url, 'http://localhost');
  const token = url.searchParams.get('token');
  if (!token) return null;
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch {
    return null;
  }
}

export function initWebSocketServer(httpServer) {
  const wss = new WebSocketServer({ server: httpServer, path: '/ws' });

  wss.on('connection', (socket, request) => {
    const tokenPayload = authenticate(request);

    if (!tokenPayload) {
      socket.close(1008, 'Token inválido ou ausente.');
      return;
    }

    const { sub: userId, program } = tokenPayload;

    if (program === 'partner') {
      partnerSockets.add(socket);
    } else {
      const sockets = customerSocketsByUserId.get(userId) ?? new Set();
      sockets.add(socket);
      customerSocketsByUserId.set(userId, sockets);
    }

    console.log(`[WS][CONNECT] ${program}:${userId}`);

    socket.on('close', () => {
      partnerSockets.delete(socket);
      const sockets = customerSocketsByUserId.get(userId);
      if (sockets) {
        sockets.delete(socket);
        if (sockets.size === 0) customerSocketsByUserId.delete(userId);
      }
      console.log(`[WS][DISCONNECT] ${program}:${userId}`);
    });
  });

  console.log('[WS] Servidor WebSocket inicializado em /ws');
  return wss;
}
