import cors from 'cors';

const corsOptions = {
  origin: (origin, callback) => {
    // permite qualquer origem (útil para desenvolvimento); retorna a origem solicitada
    callback(null, true);
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  exposedHeaders: ['Authorization']
};

export default cors(corsOptions);
