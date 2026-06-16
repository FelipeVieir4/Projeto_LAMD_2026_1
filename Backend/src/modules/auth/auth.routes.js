import { Router } from 'express';
import { authenticateJwt } from './auth.middleware.js';
import { changePassword, login, me, register, updateProfile } from './auth.controller.js';

const authRoutes = Router();

authRoutes.post('/register', register);
authRoutes.post('/login', login);
authRoutes.get('/me', authenticateJwt, me);
authRoutes.patch('/profile', authenticateJwt, updateProfile);
authRoutes.patch('/password', authenticateJwt, changePassword);

export default authRoutes;