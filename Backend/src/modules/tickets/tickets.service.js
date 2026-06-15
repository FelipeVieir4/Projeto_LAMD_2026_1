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

function isUuid(value) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function normalizeStatus(status) {
  return String(status ?? '').trim().toLowerCase();
}

function validateStatusChange(ticket, status, user) {
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
}

function normalizeTicketFields(data) {
  const ticketId = String(data?.ticketId ?? '').trim();
  const specialty = String(data?.specialty ?? '').trim();
  const title = String(data?.title ?? '').trim();

  if (!ticketId) throw createError('Informe o UUID do chamado.', 'MISSING_TICKET_ID', 400);
  if (!isUuid(ticketId)) throw createError('UUID do chamado inválido.', 'INVALID_TICKET_ID', 400);
  if (!specialty) throw createError('Informe a especialidade do chamado.', 'MISSING_SPECIALTY', 400);
  if (!title) throw createError('Informe o título do chamado.', 'MISSING_TITLE', 400);

  return {
    ticketId,
    specialty,
    title,
    description: data?.description ?? null,
    addressText: data?.addressText ?? null
  };
}

//envia o ticket para a fila, onde o worker irá processar e criar o ticket no banco de dados, garantindo a consistência mesmo que haja falhas no processo. O cliente recebe uma resposta imediata de que o ticket foi recebido e está sendo processado. 
export async function createTicket(user, data) {
  if (user.program !== 'customer') {
    throw createError('Apenas clientes podem abrir chamados.', 'FORBIDDEN', 403);
  }

  const ticket = normalizeTicketFields(data);

  await publishEvent(Events.TICKET_CREATION_REQUESTED, {
    ticketId: ticket.ticketId,
    customerId: user.id,
    specialty: ticket.specialty,
    title: ticket.title,
    description: ticket.description,
    addressText: ticket.addressText,
    requestedBy: user.id,
    requestedByProgram: user.program,
    requestedAt: new Date().toISOString()
  });

  return {
    id: ticket.ticketId,
    customerId: user.id,
    specialty: ticket.specialty,
    title: ticket.title,
    description: ticket.description,
    addressText: ticket.addressText,
    status: 'pending'
  };
}

// O worker irá consumir a mensagem de criação, processar o ticket e criar o registro no banco de dados. Após a criação, ele publicará um evento de "ticket criado" para notificar outros serviços ou componentes do sistema sobre a nova criação.
export async function processTicketCreationRequest(payload) {
  const ticket = normalizeTicketFields(payload);

  if (!String(payload?.customerId ?? '').trim()) {
    throw createError('O comando de criação precisa conter customerId.', 'MISSING_CUSTOMER_ID', 400);
  }

  const createdTicket = await dbCreateTicket({
    id: ticket.ticketId,
    customerId: payload.customerId,
    specialty: ticket.specialty,
    title: ticket.title,
    description: ticket.description,
    addressText: ticket.addressText
  });

  await publishEvent(Events.TICKET_CREATED, {
    ticketId: createdTicket.id,
    customerId: createdTicket.customerId,
    specialty: createdTicket.specialty,
    title: createdTicket.title,
    description: createdTicket.description,
    addressText: createdTicket.addressText,
    createdAt: createdTicket.createdAt,
    processedAt: new Date().toISOString()
  });

  return createdTicket;
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

  const requestedStatus = normalizeStatus(status);
  validateStatusChange(ticket, requestedStatus, user);

  await publishEvent(Events.TICKET_STATUS_CHANGE_REQUESTED, {
    ticketId: ticket.id,
    currentStatus: ticket.status,
    requestedStatus,
    requestedBy: user.id,
    requestedByProgram: user.program,
    partnerId: ticket.partnerId,
    requestedAt: new Date().toISOString()
  });

  return {
    id: ticket.id,
    customerId: ticket.customerId,
    partnerId: ticket.partnerId,
    specialty: ticket.specialty,
    title: ticket.title,
    description: ticket.description,
    addressText: ticket.addressText,
    status: ticket.status,
    requestedStatus,
    queued: true
  };
}

export async function processTicketStatusChangeRequest(payload) {
  const ticketId = String(payload?.ticketId ?? '').trim();
  const requestedStatus = normalizeStatus(payload?.requestedStatus ?? payload?.status);
  const requestedBy = String(payload?.requestedBy ?? '').trim();
  const requestedByProgram = String(payload?.requestedByProgram ?? '').trim().toLowerCase();

  if (!ticketId) throw createError('O comando de status precisa conter ticketId.', 'MISSING_TICKET_ID', 400);
  if (!isUuid(ticketId)) throw createError('UUID do chamado inválido.', 'INVALID_TICKET_ID', 400);
  if (!requestedBy) throw createError('O comando de status precisa conter requestedBy.', 'MISSING_REQUESTED_BY', 400);
  if (!requestedByProgram) {
    throw createError('O comando de status precisa conter requestedByProgram.', 'MISSING_REQUESTED_BY_PROGRAM', 400);
  }

  const ticket = await findTicketById(ticketId);

  if (!ticket) throw createError('Chamado não encontrado.', 'NOT_FOUND', 404);

  const user = { id: requestedBy, program: requestedByProgram };
  validateStatusChange(ticket, requestedStatus, user);

  const partnerId = user.program === 'partner' ? user.id : ticket.partnerId;
  const updated = await dbUpdateTicketStatus(ticketId, { status: requestedStatus, partnerId });

  await publishEvent(Events.TICKET_STATUS_CHANGED, {
    ticketId: updated.id,
    previousStatus: ticket.status,
    newStatus: updated.status,
    updatedBy: user.id,
    updatedByProgram: user.program,
    partnerId: updated.partnerId,
    updatedAt: updated.updatedAt,
    processedAt: new Date().toISOString()
  });

  return updated;
}
