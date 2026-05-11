import { getAuthenticatedAccount } from './auth.service.js';

export function authenticateJwt(request, response, next) {
  try {
    const result = getAuthenticatedAccount(request.headers.authorization);
    request.auth = result.tokenPayload;
    request.user = result.user;
    next();
  } catch (error) {
    response.status(error.status ?? 401).json({
      error: error.code ?? 'UNAUTHORIZED',
      message: error.message ?? 'Acesso não autorizado.'
    });
  }
}