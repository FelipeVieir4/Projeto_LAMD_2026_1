import { Router } from 'express';
import { listSpecialties } from './specialties.controller.js';

const specialtiesRoutes = Router();

specialtiesRoutes.get('/', listSpecialties);

export default specialtiesRoutes;