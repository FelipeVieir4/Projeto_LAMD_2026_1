import {
  createTicket,
  getTicket,
  listTickets,
  updateTicketStatus
} from './tickets.service.js';

export async function create(req, res) {
  try {
    const ticket = await createTicket(req.user, req.body);
    return res.status(202).json({ success: true, data: ticket });
  } catch (err) {
    return res.status(err.status ?? 500).json({ success: false, code: err.code, message: err.message });
  }
}

export async function findById(req, res) {
  try {
    const ticket = await getTicket(req.params.id, req.user);
    return res.json({ success: true, data: ticket });
  } catch (err) {
    return res.status(err.status ?? 500).json({ success: false, code: err.code, message: err.message });
  }
}

export async function list(req, res) {
  try {
    const filters = {
      status: req.query.status,
      pending: req.query.pending === 'true'
    };
    const tickets = await listTickets(req.user, filters);
    return res.json({ success: true, data: tickets, total: tickets.length });
  } catch (err) {
    return res.status(err.status ?? 500).json({ success: false, code: err.code, message: err.message });
  }
}

export async function updateStatus(req, res) {
  try {
    const ticket = await updateTicketStatus(req.params.id, {
      status: req.body.status,
      user: req.user
    });
    return res.status(202).json({ success: true, data: ticket });
  } catch (err) {
    return res.status(err.status ?? 500).json({ success: false, code: err.code, message: err.message });
  }
}
