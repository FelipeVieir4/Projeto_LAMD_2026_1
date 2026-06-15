import { listSpecialtiesService } from './specialties.service.js';

export async function listSpecialties(request, response) {
  try {
    const specialties = await listSpecialtiesService();
    response.status(200).json({ specialties });
  } catch (error) {
    response.status(error.status ?? 500).json({
      error: error.code ?? 'INTERNAL_SERVER_ERROR',
      message: error.message ?? 'Erro inesperado.'
    });
  }
}