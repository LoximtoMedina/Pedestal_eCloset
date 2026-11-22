import { createContext, useContext, useState, type ReactNode } from 'react';

// Representa la sesión activa del usuario basada en tu modelo (Persona / Cuenta / Usuario)
export interface SessionUser {
  idUsuario: number;
  idCuenta: number;
  nombreUsuario: string;
  correo: string;
  primerNombre: string;
  primerApellido: string;
  avatarSrc?: string;
  role?: string;
  permissions?: string[];
}

export interface LoginMockPayload {
  identifier?: string; // Puede ser correo o nombreUsuario ingresado en Login
  nombreUsuario?: string;
  correo?: string;
  primerNombre?: string;
  primerApellido?: string;
  avatarSrc?: string;
}

export interface AuthContextValue {
  isAuthenticated: boolean;
  user: SessionUser | null;
  loginMock: (customUser?: Partial<SessionUser> & { identifier?: string }) => void;
  logoutMock: () => void;
  hasPermission: (permission?: string) => boolean;
}

// usuario simulado
const DEFAULT_MOCK_USER: SessionUser = {
  idUsuario: 1,
  idCuenta: 1,
  nombreUsuario: 'carlos.mejia',
  correo: 'carlos.mejia@pedestal.hn',
  primerNombre: 'Carlos',
  primerApellido: 'Mejía',
  avatarSrc: '',
  role: 'admin',
  permissions: ['dashboard.view', 'ecloset.access'],
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export function getDashboardRoute(role?: string): string {
  switch (role) {
    case 'store_manager':
    case 'jefe_tienda':
      return '/dashboards/store';
    case 'area_manager':
    case 'jefe_area':
      return '/dashboards/area';
    case 'national_manager':
    case 'jefe_nacional':
      return '/dashboards/national';
    case 'admin':
      return '/dashboards/national';
    default:
      return '/dashboards/store';
  }
}

export function AuthProvider({ children }: AuthProviderProps) {
  // Cambia a `true` si quieres arrancar ya con sesión simulada activa, o `false` para probar desde el login
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [user, setUser] = useState<SessionUser | null>(DEFAULT_MOCK_USER);

  // Simula inicio de sesión tomando lo que venga del formulario o completando con datos de prueba
  const loginMock = (payload?: LoginMockPayload) => {
    const rawIdentifier = payload?.identifier?.trim() || '';
    const isEmail = rawIdentifier.includes('@');

    const resolvedCorreo =
      payload?.correo?.trim() ||
      (isEmail ? rawIdentifier : DEFAULT_MOCK_USER.correo);

    const resolvedNombreUsuario =
      payload?.nombreUsuario?.trim() ||
      (!isEmail && rawIdentifier
        ? rawIdentifier
        : isEmail
          ? rawIdentifier.split('@')[0]
          : DEFAULT_MOCK_USER.nombreUsuario);

    const nextUser: SessionUser = {
      ...DEFAULT_MOCK_USER,
      nombreUsuario: resolvedNombreUsuario,
      correo: resolvedCorreo,
      primerNombre: payload?.primerNombre?.trim() || DEFAULT_MOCK_USER.primerNombre,
      primerApellido: payload?.primerApellido?.trim() || DEFAULT_MOCK_USER.primerApellido,
      avatarSrc: payload?.avatarSrc ?? DEFAULT_MOCK_USER.avatarSrc,
    };

    setUser(nextUser);
    setIsAuthenticated(true);
  };

  // Simula cerrar sesión
  const logoutMock = () => {
    setIsAuthenticated(false);
    setUser(null);
  };

  const hasPermission = (permission?: string): boolean => {
    if (!permission) return true;
    if (!isAuthenticated || !user?.permissions) return false;
    return user.permissions.includes(permission);
  };

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated,
        user,
        loginMock,
        logoutMock,
        hasPermission,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth debe usarse dentro de un AuthProvider');
  }
  return context;
}