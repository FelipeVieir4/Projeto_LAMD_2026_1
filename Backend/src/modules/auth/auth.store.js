import crypto from 'node:crypto';

const usersByProgram = {
  customer: new Map(),
  partner: new Map()
};

const usersById = new Map();

const programAliases = new Map([
  ['customer', 'customer'],
  ['client', 'customer'],
  ['cliente', 'customer'],
  ['partner', 'partner'],
  ['parceiro', 'partner']
]);

export function normalizeProgram(program) {
  const normalized = String(program ?? '').trim().toLowerCase();
  return programAliases.get(normalized) ?? null;
}

function normalizeEmail(email) {
  return String(email ?? '').trim().toLowerCase();
}

function normalizeSpecialties(specialties) {
  if (!specialties) {
    return [];
  }

  if (Array.isArray(specialties)) {
    return specialties.map((specialty) => String(specialty).trim()).filter(Boolean);
  }

  return String(specialties)
    .split(',')
    .map((specialty) => specialty.trim())
    .filter(Boolean);
}

export function findUserByEmail(program, email) {
  const normalizedProgram = normalizeProgram(program);

  if (!normalizedProgram) {
    return null;
  }

  return usersByProgram[normalizedProgram].get(normalizeEmail(email)) ?? null;
}

export function findUserById(program, id) {
  const normalizedProgram = normalizeProgram(program);

  if (!normalizedProgram) {
    return null;
  }

  const user = usersById.get(String(id));

  if (!user || user.program !== normalizedProgram) {
    return null;
  }

  return user;
}

export function createUser(program, userData) {
  const normalizedProgram = normalizeProgram(program);

  if (!normalizedProgram) {
    const error = new Error('Programa inválido. Use customer ou partner.');
    error.code = 'INVALID_PROGRAM';
    error.status = 400;
    throw error;
  }

  const email = normalizeEmail(userData.email);

  if (usersByProgram[normalizedProgram].has(email)) {
    const error = new Error('Já existe um usuário cadastrado com este e-mail para este programa.');
    error.code = 'USER_ALREADY_EXISTS';
    error.status = 409;
    throw error;
  }

  const now = new Date().toISOString();
  const user = {
    id: crypto.randomUUID(),
    program: normalizedProgram,
    email,
    passwordHash: userData.passwordHash,
    name: userData.name ?? null,
    phone: userData.phone ?? null,
    document: userData.document ?? null,
    companyName: userData.companyName ?? null,
    bio: userData.bio ?? null,
    specialties: normalizeSpecialties(userData.specialties),
    status: normalizedProgram === 'customer' ? 'active' : 'pending',
    isActive: true,
    createdAt: now,
    updatedAt: now
  };

  usersByProgram[normalizedProgram].set(email, user);
  usersById.set(user.id, user);

  return user;
}

export function sanitizeUser(user) {
  if (!user) {
    return null;
  }

  const base = {
    id: user.id,
    program: user.program,
    email: user.email,
    phone: user.phone,
    status: user.status,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt
  };

  if (user.program === 'customer') {
    return {
      ...base,
      name: user.name
    };
  }

  return {
    ...base,
    document: user.document,
    companyName: user.companyName,
    bio: user.bio,
    specialties: user.specialties,
    isActive: user.isActive
  };
}