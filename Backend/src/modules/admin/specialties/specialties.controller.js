import {
  createSpecialtyService,
  deleteSpecialtyService,
  listSpecialtiesService,
  updateSpecialtyService
} from './specialties.service.js';

function handleAdminError(response, error) {
  response.status(error.status ?? 500).json({
    error: error.code ?? 'INTERNAL_SERVER_ERROR',
    message: error.message ?? 'Erro inesperado.'
  });
}

export async function listSpecialties(request, response) {
  try {
    const data = await listSpecialtiesService(request.query);
    response.status(200).json({ specialties: data });
  } catch (error) {
    handleAdminError(response, error);
  }
}

export async function createSpecialty(request, response) {
  try {
    const specialty = await createSpecialtyService(request.body);
    response.status(201).json({ specialty });
  } catch (error) {
    handleAdminError(response, error);
  }
}

export async function updateSpecialty(request, response) {
  try {
    const specialty = await updateSpecialtyService(request.params.id, request.body);
    response.status(200).json({ specialty });
  } catch (error) {
    handleAdminError(response, error);
  }
}

export async function deleteSpecialty(request, response) {
  try {
    const result = await deleteSpecialtyService(request.params.id);
    response.status(200).json(result);
  } catch (error) {
    handleAdminError(response, error);
  }
}
