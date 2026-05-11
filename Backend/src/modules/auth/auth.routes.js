import { Router } from 'express';
import { authenticateJwt } from './auth.middleware.js';
import { login, me, register } from './auth.controller.js';

const authRoutes = Router();

authRoutes.post('/register', register);
authRoutes.post('/login', login);
authRoutes.get('/me', authenticateJwt, me);

export default authRoutes;