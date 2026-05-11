import express from 'express';
import routes from './routes/index.js';
import cors from './config/cors.js';

const app = express();

app.use(cors);
// tratar requisições OPTIONS (preflight)
app.options('*', cors);

app.use(express.json());
app.use(routes);

export default app;