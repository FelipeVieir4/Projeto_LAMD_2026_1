import { Router } from 'express';
import { authenticateJwt } from '../../auth/auth.middleware.js';
import { authenticateAdminKey } from '../admin.middleware.js';
import {
  createSpecialty,
  deleteSpecialty,
  listSpecialties,
  updateSpecialty
} from './specialties.controller.js';

const specialtiesRoutes = Router();

specialtiesRoutes.use(authenticateJwt, authenticateAdminKey);

specialtiesRoutes.get('/specialties', listSpecialties);
specialtiesRoutes.post('/specialties', createSpecialty);
specialtiesRoutes.put('/specialties/:id', updateSpecialty);
specialtiesRoutes.delete('/specialties/:id', deleteSpecialty);

export default specialtiesRoutes;
