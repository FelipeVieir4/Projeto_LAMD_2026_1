import { Router } from 'express';
import { authenticateJwt } from '../auth/auth.middleware.js';
import { create, findById, list, updateStatus } from './tickets.controller.js';

const ticketsRoutes = Router();

ticketsRoutes.use(authenticateJwt);

ticketsRoutes.post('/', create);
ticketsRoutes.get('/', list);
ticketsRoutes.get('/:id', findById);
ticketsRoutes.patch('/:id/status', updateStatus);

export default ticketsRoutes;
