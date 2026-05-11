import {
  createSpecialty,
  deleteSpecialty,
  listSpecialties,
  updateSpecialty
} from './specialties.store.js';

function createApiError(message, code, status) {
  const error = new Error(message);
  error.code = code;
  error.status = status;
  return error;
}

function normalizeName(name) {
  return String(name ?? '').trim();
}

function normalizeDescription(description) {
  const value = String(description ?? '').trim();
  return value || null;
}

function normalizeOptionalBoolean(value) {
  if (value === undefined) {
    return undefined;
  }

  if (typeof value === 'boolean') {
    return value;
  }

  const normalized = String(value).trim().toLowerCase();

  if (normalized === 'true') {
    return true;
  }

  if (normalized === 'false') {
    return false;
  }

  throw createApiError('isActive precisa ser boolean.', 'INVALID_IS_ACTIVE', 400);
}

function mapDatabaseError(error) {
  if (error?.code === '23505') {
    throw createApiError('Já existe especialidade com este nome.', 'SPECIALTY_ALREADY_EXISTS', 409);
  }

  throw error;
}

export async function listSpecialtiesService(queryParams) {
  const includeInactive = String(queryParams?.includeInactive ?? '').trim().toLowerCase() === 'true';
  return listSpecialties({ includeInactive });
}

export async function createSpecialtyService(payload) {
  const name = normalizeName(payload?.name);

  if (!name) {
    throw createApiError('Informe o nome da especialidade.', 'MISSING_SPECIALTY_NAME', 400);
  }

  try {
    return await createSpecialty({
      name,
      description: normalizeDescription(payload?.description),
      isActive: normalizeOptionalBoolean(payload?.isActive) ?? true
    });
  } catch (error) {
    mapDatabaseError(error);
  }
}

export async function updateSpecialtyService(id, payload) {
  const specialtyId = String(id ?? '').trim();

  if (!specialtyId) {
    throw createApiError('Informe o id da especialidade.', 'MISSING_SPECIALTY_ID', 400);
  }

  const patch = {};

  if (payload?.name !== undefined) {
    const name = normalizeName(payload.name);

    if (!name) {
      throw createApiError('name não pode ser vazio.', 'INVALID_SPECIALTY_NAME', 400);
    }

    patch.name = name;
  }

  if (payload?.description !== undefined) {
    patch.description = normalizeDescription(payload.description);
  }

  patch.isActive = normalizeOptionalBoolean(payload?.isActive);

  if (Object.values(patch).every((value) => value === undefined)) {
    throw createApiError('Envie ao menos um campo para atualização.', 'EMPTY_UPDATE_PAYLOAD', 400);
  }

  try {
    const updated = await updateSpecialty(specialtyId, patch);

    if (!updated) {
      throw createApiError('Especialidade não encontrada.', 'SPECIALTY_NOT_FOUND', 404);
    }

    return updated;
  } catch (error) {
    mapDatabaseError(error);
  }
}

export async function deleteSpecialtyService(id) {
  const specialtyId = String(id ?? '').trim();

  if (!specialtyId) {
    throw createApiError('Informe o id da especialidade.', 'MISSING_SPECIALTY_ID', 400);
  }

  const deleted = await deleteSpecialty(specialtyId);

  if (!deleted) {
    throw createApiError('Especialidade não encontrada.', 'SPECIALTY_NOT_FOUND', 404);
  }

  return {
    deleted: true,
    id: specialtyId
  };
}
