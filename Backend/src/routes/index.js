import { Router } from 'express';
import swaggerUi from 'swagger-ui-express';
import { swaggerDocument } from '../config/swagger.js';
import authRoutes from '../modules/auth/auth.routes.js';
import specialtiesRoutes from '../modules/admin/specialties/specialties.routes.js';
import healthRoutes from '../modules/health/health.routes.js';

const routes = Router();

// Serve o JSON do Swagger com `servers` dinâmico baseado na requisição
routes.get('/docs/swagger.json', (req, res) => {
	const doc = JSON.parse(JSON.stringify(swaggerDocument));
	const protocol = req.protocol;
	const host = req.get('host');
	doc.servers = [
		{
			url: `${protocol}://${host}`,
			description: 'Servidor (dinâmico)'
		}
	];
	res.json(doc);
});

// Carrega o Swagger UI apontando para o JSON dinâmico
routes.use('/docs', swaggerUi.serve, swaggerUi.setup(null, { swaggerOptions: { url: '/docs/swagger.json' } }));
routes.use('/auth', authRoutes);
routes.use('/admin', specialtiesRoutes);
routes.use(healthRoutes);

export default routes;