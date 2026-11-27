// Define los campos enviados al iniciar sesión (coincide con LoginRequestDto del backend).
export interface LoginRequestPayload {
  identifier: string;
  password: string;
  rememberMe?: boolean;
}

// Define los campos enviados al registrar una cuenta (coincide con RegisterRequestDto del backend).
export interface RegisterRequestPayload {
  documentNumber: string;
  phone: string;
  firstName: string;
  middleName?: string;
  firstSurname: string;
  secondSurname?: string;
  email: string;
  username: string;
  city: string;
  addressLine: string;
  password: string;
  confirmPassword: string;
}

// Define el usuario autenticado devuelto por el backend (coincide con SessionUserDto).
export interface SessionUserData {
  accountId: number;
  userId: number | null;
  employeeId: number | null;
  username: string;
  email: string;
  firstName: string;
  firstSurname: string;
  roles: string[];
  permissions: string[];
  storeId: number | null;
  areaId: number | null;
  initialRoute: string;
}

// Define la respuesta completa de login y register (coincide con AuthResponseDto).
export interface AuthResponseData {
  token: string;
  expiresAt: string;
  user: SessionUserData;
}

// URL base de la API configurable por entorno (.env), con respaldo local.
const apiBaseUrl = (
  import.meta.env.VITE_API_BASE_URL ?? 'https://localhost:7139'
).replace(/\/+$/, '');

const authTokenStorageKey = 'pedestal_auth_token';

// Lee el token guardado en localStorage o sessionStorage.
export function getStoredAuthToken(): string | null {
  return (
    localStorage.getItem(authTokenStorageKey) ??
    sessionStorage.getItem(authTokenStorageKey)
  );
}

// Guarda el token según si el usuario marcó "Mantener sesión iniciada".
export function saveAuthToken(token: string, persistSession = true): void {
  clearAuthToken();
  if (persistSession) {
    localStorage.setItem(authTokenStorageKey, token);
  } else {
    sessionStorage.setItem(authTokenStorageKey, token);
  }
}

// Elimina el token de ambos almacenamientos al cerrar sesión.
export function clearAuthToken(): void {
  localStorage.removeItem(authTokenStorageKey);
  sessionStorage.removeItem(authTokenStorageKey);
}

// Extrae un mensaje legible desde ProblemDetails o respuestas de error del backend.
async function parseApiError(response: Response): Promise<string> {
  try {
    const errorBody = await response.json();
    if (typeof errorBody?.detail === 'string' && errorBody.detail.trim()) {
      return errorBody.detail;
    }
    if (typeof errorBody?.title === 'string' && errorBody.title.trim()) {
      return errorBody.title;
    }
    if (errorBody?.errors && typeof errorBody.errors === 'object') {
      const firstFieldErrors = Object.values(errorBody.errors).flat();
      if (firstFieldErrors.length > 0) {
        return String(firstFieldErrors[0]);
      }
    }
  } catch {
    // Si la respuesta no es JSON válido, se usa el texto de estado HTTP.
  }

  return response.statusText || `Error HTTP ${response.status}`;
}

// Realiza el inicio de sesión contra POST /api/auth/login.
export async function loginUser(
  payload: LoginRequestPayload
): Promise<AuthResponseData> {
  const response = await fetch(`${apiBaseUrl}/api/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      identifier: payload.identifier.trim(),
      password: payload.password,
      rememberMe: Boolean(payload.rememberMe),
    }),
  });

  if (!response.ok) {
    const errorMessage = await parseApiError(response);
    throw new Error(errorMessage);
  }

  return (await response.json()) as AuthResponseData;
}

// Realiza el registro de cliente contra POST /api/auth/register.
export async function registerUser(
  payload: RegisterRequestPayload
): Promise<AuthResponseData> {
  const response = await fetch(`${apiBaseUrl}/api/auth/register`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      documentNumber: payload.documentNumber.trim(),
      phone: payload.phone.trim(),
      firstName: payload.firstName.trim(),
      middleName: payload.middleName?.trim() || null,
      firstSurname: payload.firstSurname.trim(),
      secondSurname: payload.secondSurname?.trim() || null,
      email: payload.email.trim(),
      username: payload.username.trim(),
      city: payload.city.trim(),
      addressLine: payload.addressLine.trim(),
      password: payload.password,
      confirmPassword: payload.confirmPassword,
    }),
  });

  if (!response.ok) {
    const errorMessage = await parseApiError(response);
    throw new Error(errorMessage);
  }

  return (await response.json()) as AuthResponseData;
}

// Obtiene la sesión actual usando el Bearer token contra GET /api/auth/me.
export async function getCurrentSessionUser(
  token?: string | null
): Promise<SessionUserData> {
  const activeToken = token ?? getStoredAuthToken();

  if (!activeToken) {
    throw new Error('No hay un token de sesión disponible.');
  }

  const response = await fetch(`${apiBaseUrl}/api/auth/me`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${activeToken}`,
      Accept: 'application/json',
    },
  });

  if (!response.ok) {
    const errorMessage = await parseApiError(response);
    throw new Error(errorMessage);
  }

  return (await response.json()) as SessionUserData;
}