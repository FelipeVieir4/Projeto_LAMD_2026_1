import { getAuthenticatedAccount, loginAccount, registerAccount } from './auth.service.js';

function handleAuthError(response, error) {
  const status = error.status ?? 500;
  response.status(status).json({
    error: error.code ?? 'INTERNAL_SERVER_ERROR',
    message: error.message ?? 'Erro inesperado.'
  });
}

export async function register(request, response) {
  try {
    const result = await registerAccount(request.body);
    response.status(201).json(result);
  } catch (error) {
    handleAuthError(response, error);
  }
}

export async function login(request, response) {
  try {
    const result = await loginAccount(request.body);
    response.status(200).json(result);
  } catch (error) {
    handleAuthError(response, error);
  }
}

export async function me(request, response) {
  try {
    const result = await getAuthenticatedAccount(request.headers.authorization);
    response.status(200).json(result);
  } catch (error) {
    handleAuthError(response, error);
  }
}