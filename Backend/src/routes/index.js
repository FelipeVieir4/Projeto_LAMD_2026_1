import { Router } from 'express';
import swaggerUi from 'swagger-ui-express';
import { swaggerDocument } from '../config/swagger.js';
import authRoutes from '../modules/auth/auth.routes.js';
import healthRoutes from '../modules/health/health.routes.js';

const routes = Router();

routes.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
routes.use('/auth', authRoutes);
routes.use(healthRoutes);

export default routes;