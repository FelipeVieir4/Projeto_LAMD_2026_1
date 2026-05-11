function unauthorized(response, message = 'Acesso administrativo não autorizado.') {
  response.status(401).json({
    error: 'ADMIN_UNAUTHORIZED',
    message
  });
}

export function authenticateAdminKey(request, response, next) {
  const expectedApiKey = String(process.env.ADMIN_API_KEY ?? '').trim();

  if (!expectedApiKey) {
    response.status(503).json({
      error: 'ADMIN_KEY_NOT_CONFIGURED',
      message: 'Defina ADMIN_API_KEY para habilitar as rotas administrativas.'
    });
    return;
  }

  const providedApiKey = String(request.headers['x-admin-key'] ?? '').trim();

  if (!providedApiKey) {
    unauthorized(response, 'Informe o header x-admin-key.');
    return;
  }

  if (providedApiKey !== expectedApiKey) {
    unauthorized(response);
    return;
  }

  next();
}
