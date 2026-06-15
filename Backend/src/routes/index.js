import { Router } from 'express';
import swaggerUi from 'swagger-ui-express';
import { swaggerDocument } from '../config/swagger.js';
import authRoutes from '../modules/auth/auth.routes.js';
import specialtiesRoutes from '../modules/admin/specialties/specialties.routes.js';
import healthRoutes from '../modules/health/health.routes.js';
import ticketsRoutes from '../modules/tickets/tickets.routes.js';
import appSpecialtiesRoutes from '../modules/specialties/specialties.routes.js';

const routes = Router();

routes.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
routes.use('/auth', authRoutes);
routes.use('/specialties', appSpecialtiesRoutes);
routes.use('/admin', specialtiesRoutes);
routes.use('/tickets', ticketsRoutes);
routes.use(healthRoutes);

export default routes;