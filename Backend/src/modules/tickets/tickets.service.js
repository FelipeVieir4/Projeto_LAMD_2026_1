import {
  createTicket as dbCreateTicket,
  findTicketById,
  listTickets as dbListTickets,
  listPendingTickets,
  updateTicketStatus as dbUpdateTicketStatus
} from './tickets.store.js';
import { publishEvent, Events } from '../../messaging/publisher.js';

const VALID_STATUSES = ['pending', 'accepted', 'in_progress', 'completed', 'cancelled'];

const ALLOWED_TRANSITIONS = {
  pending: ['accepted', 'cancelled'],
  accepted: ['in_progress', 'cancelled'],
  in_progress: ['completed', 'cancelled'],
  completed: [],
  cancelled: []
};

function createError(message, code, status) {
  const err = new Error(message);
  err.code = code;
  err.status = status;
  return err;
}

export async function createTicket(user, data) {
  if (user.program !== 'customer') {
    throw createError('Apenas clientes podem abrir chamados.', 'FORBIDDEN', 403);
  }

  const specialty = String(data?.specialty ?? '').trim();
  const title = String(data?.title ?? '').trim();

  if (!specialty) throw createError('Informe a especialidade do chamado.', 'MISSING_SPECIALTY', 400);
  if (!title) throw createError('Informe o título do chamado.', 'MISSING_TITLE', 400);

  const ticket = await dbCreateTicket({
    customerId: user.id,
    specialty,
    title,
    description: data?.description ?? null,
    addressText: data?.addressText ?? null
  });

  await publishEvent(Events.TICKET_CREATED, {
    ticketId: ticket.id,
    customerId: ticket.customerId,
    specialty: ticket.specialty,
    title: ticket.title,
    description: ticket.description,
    addressText: ticket.addressText,
    createdAt: ticket.createdAt
  });

  return ticket;
}

export async function getTicket(id, user) {
  const ticket = await findTicketById(id);

  if (!ticket) throw createError('Chamado não encontrado.', 'NOT_FOUND', 404);

  if (user.program === 'customer' && ticket.customerId !== user.id) {
    throw createError('Acesso negado a este chamado.', 'FORBIDDEN', 403);
  }

  return ticket;
}

export async function listTickets(user, filters = {}) {
  if (user.program === 'customer') {
    return dbListTickets({ customerId: user.id, status: filters.status });
  }

  if (filters.pending) {
    return listPendingTickets();
  }

  return dbListTickets({ partnerId: user.id, status: filters.status });
}

export async function updateTicketStatus(id, { status, user }) {
  const ticket = await findTicketById(id);

  if (!ticket) throw createError('Chamado não encontrado.', 'NOT_FOUND', 404);

  if (!VALID_STATUSES.includes(status)) {
    throw createError(
      `Status inválido. Valores aceitos: ${VALID_STATUSES.join(', ')}.`,
      'INVALID_STATUS',
      400
    );
  }

  const allowed = ALLOWED_TRANSITIONS[ticket.status] ?? [];
  if (!allowed.includes(status)) {
    throw createError(
      `Transição inválida: ${ticket.status} → ${status}.`,
      'INVALID_TRANSITION',
      422
    );
  }

  if (user.program === 'customer' && status !== 'cancelled') {
    throw createError('Clientes só podem cancelar chamados.', 'FORBIDDEN', 403);
  }

  if (user.program === 'partner' && ticket.partnerId && ticket.partnerId !== user.id) {
    throw createError('Este chamado já pertence a outro parceiro.', 'FORBIDDEN', 403);
  }

  const partnerId = user.program === 'partner' ? user.id : ticket.partnerId;
  const updated = await dbUpdateTicketStatus(id, { status, partnerId });

  await publishEvent(Events.TICKET_STATUS_CHANGED, {
    ticketId: updated.id,
    previousStatus: ticket.status,
    newStatus: updated.status,
    updatedBy: user.id,
    updatedByProgram: user.program,
    partnerId: updated.partnerId,
    updatedAt: updated.updatedAt
  });

  return updated;
}
