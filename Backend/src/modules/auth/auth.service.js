import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import {
  createUser,
  findUserByEmail,
  findUserById,
  normalizeProgram,
  sanitizeUser,
  updateCustomer,
  updateCustomerPassword
} from './auth.store.js';

const JWT_SECRET = process.env.JWT_SECRET ?? 'dev-secret-change-me';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? '1d';
const PASSWORD_MIN_LENGTH = parseInt(process.env.PASSWORD_MIN_LENGTH ?? '8', 10);
const PBKDF2_ITERATIONS = parseInt(process.env.PBKDF2_ITERATIONS ?? '120000', 10);
const PBKDF2_KEY_LENGTH = parseInt(process.env.PBKDF2_KEY_LENGTH ?? '64', 10);
const PBKDF2_DIGEST = process.env.PBKDF2_DIGEST ?? 'sha512';

function createAuthError(message, code, status) {
  const error = new Error(message);
  error.code = code;
  error.status = status;
  return error;
}

function normalizePassword(password) {
  return String(password ?? '');
}

function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto
    .pbkdf2Sync(normalizePassword(password), salt, PBKDF2_ITERATIONS, PBKDF2_KEY_LENGTH, PBKDF2_DIGEST)
    .toString('hex');

  return `${salt}:${hash}`;
}

function verifyPassword(password, storedHash) {
  const [salt, expectedHash] = String(storedHash ?? '').split(':');

  if (!salt || !expectedHash) {
    return false;
  }

  const derivedHash = crypto
    .pbkdf2Sync(normalizePassword(password), salt, PBKDF2_ITERATIONS, PBKDF2_KEY_LENGTH, PBKDF2_DIGEST)
    .toString('hex');

  const expectedBuffer = Buffer.from(expectedHash, 'hex');
  const derivedBuffer = Buffer.from(derivedHash, 'hex');

  if (expectedBuffer.length !== derivedBuffer.length) {
    return false;
  }

  return crypto.timingSafeEqual(expectedBuffer, derivedBuffer);
}

function buildTokenPayload(user) {
  return {
    sub: user.id,
    program: user.program,
    email: user.email,
    name: user.name ?? user.companyName ?? null
  };
}

function createToken(user) {
  return jwt.sign(buildTokenPayload(user), JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN
  });
}

function validateCommonFields(payload) {
  const email = String(payload?.email ?? '').trim().toLowerCase();
  const password = normalizePassword(payload?.password);

  if (!email || !email.includes('@')) {
    throw createAuthError('Informe um e-mail válido.', 'INVALID_EMAIL', 400);
  }

  if (password.length < PASSWORD_MIN_LENGTH) {
    throw createAuthError(`A senha precisa ter pelo menos ${PASSWORD_MIN_LENGTH} caracteres.`, 'WEAK_PASSWORD', 400);
  }

  return { email, password };
}

function assertProgramPayload(program, payload) {
  const normalizedProgram = normalizeProgram(program ?? payload?.program);

  if (!normalizedProgram) {
    throw createAuthError('Informe o programa da conta: customer ou partner.', 'INVALID_PROGRAM', 400);
  }

  return normalizedProgram;
}

export async function registerAccount(payload) {
  const program = assertProgramPayload(payload?.program, payload);
  const { email, password } = validateCommonFields(payload);

  const sharedData = {
    email,
    passwordHash: hashPassword(password),
    phone: payload?.phone ?? null
  };

  if (program === 'customer') {
    const name = String(payload?.name ?? '').trim();

    if (!name) {
      throw createAuthError('Informe o nome do cliente.', 'MISSING_NAME', 400);
    }

    const user = await createUser(program, {
      ...sharedData,
      name
    });

    return {
      user: sanitizeUser(user),
      token: createToken(user),
      tokenType: 'Bearer',
      expiresIn: JWT_EXPIRES_IN
    };
  }

  const companyName = String(payload?.companyName ?? '').trim();
  const document = String(payload?.document ?? '').trim();

  if (!companyName) {
    throw createAuthError('Informe o nome da empresa.', 'MISSING_COMPANY_NAME', 400);
  }

  if (!document) {
    throw createAuthError('Informe o documento do parceiro.', 'MISSING_DOCUMENT', 400);
  }

  const user = await createUser(program, {
    ...sharedData,
    companyName,
    document,
    bio: payload?.bio ?? null,
    specialties: payload?.specialties ?? []
  });

  return {
    user: sanitizeUser(user),
    token: createToken(user),
    tokenType: 'Bearer',
    expiresIn: JWT_EXPIRES_IN
  };
}

export async function loginAccount(payload) {
  const program = assertProgramPayload(payload?.program, payload);
  const { email, password } = validateCommonFields(payload);
  const user = await findUserByEmail(program, email);

  if (!user || !verifyPassword(password, user.passwordHash)) {
    throw createAuthError('Credenciais inválidas.', 'INVALID_CREDENTIALS', 401);
  }

  return {
    user: sanitizeUser(user),
    token: createToken(user),
    tokenType: 'Bearer',
    expiresIn: JWT_EXPIRES_IN
  };
}

function extractBearerToken(authorizationHeader) {
  const value = String(authorizationHeader ?? '').trim();
  const [scheme, token] = value.split(/\s+/);

  if (!scheme || scheme.toLowerCase() !== 'bearer' || !token) {
    throw createAuthError('Informe o token no formato Bearer.', 'UNAUTHORIZED', 401);
  }

  return token;
}

export async function updateProfileService(userId, program, payload) {
  if (program !== 'customer') {
    const err = new Error('Apenas clientes podem atualizar perfil pelo app.');
    err.code = 'FORBIDDEN'; err.status = 403; throw err;
  }
  const name = String(payload?.name ?? '').trim();
  if (!name) {
    const err = new Error('O nome não pode estar vazio.');
    err.code = 'INVALID_NAME'; err.status = 400; throw err;
  }
  const phone = payload?.phone ? String(payload.phone).trim() || null : null;
  const user = await updateCustomer(userId, { name, phone });
  if (!user) {
    const err = new Error('Usuário não encontrado.'); err.status = 404; throw err;
  }
  return { user: sanitizeUser(user) };
}

export async function changePasswordService(userId, program, payload) {
  if (program !== 'customer') {
    const err = new Error('Apenas clientes podem alterar senha pelo app.');
    err.code = 'FORBIDDEN'; err.status = 403; throw err;
  }
  const currentPassword = normalizePassword(payload?.currentPassword);
  const newPassword = normalizePassword(payload?.newPassword);
  if (newPassword.length < PASSWORD_MIN_LENGTH) {
    const err = new Error(`A nova senha precisa ter pelo menos ${PASSWORD_MIN_LENGTH} caracteres.`);
    err.code = 'WEAK_PASSWORD'; err.status = 400; throw err;
  }
  const user = await findUserById(program, userId);
  if (!user || !verifyPassword(currentPassword, user.passwordHash)) {
    const err = new Error('Senha atual incorreta.');
    err.code = 'INVALID_CREDENTIALS'; err.status = 401; throw err;
  }
  await updateCustomerPassword(userId, hashPassword(newPassword));
  return { message: 'Senha alterada com sucesso.' };
}

export async function getAuthenticatedAccount(authorizationHeader) {
  const token = extractBearerToken(authorizationHeader);

  let payload;

  try {
    payload = jwt.verify(token, JWT_SECRET);
  } catch (error) {
    throw createAuthError('Token inválido ou expirado.', 'UNAUTHORIZED', 401);
  }

  const user = await findUserById(payload.program, payload.sub);

  if (!user) {
    throw createAuthError('Usuário não encontrado para este token.', 'UNAUTHORIZED', 401);
  }

  return {
    user: sanitizeUser(user),
    tokenPayload: payload
  };
}