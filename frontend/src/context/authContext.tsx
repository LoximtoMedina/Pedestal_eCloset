import {
  useCallback,
  useEffect,
  useState,
  type ReactNode,
} from 'react';
import {
  clearAuthToken,
  getCurrentSessionUser,
  getStoredAuthToken,
  loginUser,
  registerUser,
  saveAuthToken,
  type LoginRequestPayload,
  type RegisterRequestPayload,
  type SessionUserData,
} from '../services/authService';
import {
  AuthContext,
  type AuthContextValue,
  type SessionUser,
} from './authContextInstance';

export type { AuthContextValue, SessionUser };

// El hook useAuth y la ruta por rol viven en hooks/authHook.ts; se vuelven a exportar
// aquí para que las páginas los importen siempre desde el mismo archivo.
export { getDashboardRoute, useAuth } from '../hooks/authHook';

interface AuthProviderProps {
  children: ReactNode;
}

function mapSessionUser(data: SessionUserData): SessionUser {
  return {
    ...data,
    avatarSrc: '',
  };
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [isLoadingSession, setIsLoadingSession] = useState<boolean>(true);

  useEffect(() => {
    let cancelled = false;

    const initSession = async () => {
      const token = getStoredAuthToken();
      if (!token) {
        if (!cancelled) {
          setUser(null);
          setIsAuthenticated(false);
          setIsLoadingSession(false);
        }
        return;
      }

      try {
        const me = await getCurrentSessionUser(token);
        if (!cancelled) {
          setUser(mapSessionUser(me));
          setIsAuthenticated(true);
        }
      } catch {
        clearAuthToken();
        if (!cancelled) {
          setUser(null);
          setIsAuthenticated(false);
        }
      } finally {
        if (!cancelled) {
          setIsLoadingSession(false);
        }
      }
    };

    void initSession();

    return () => {
      cancelled = true;
    };
  }, []);

  const refreshSession = useCallback(async (): Promise<SessionUser | null> => {
    const token = getStoredAuthToken();
    if (!token) {
      setUser(null);
      setIsAuthenticated(false);
      setIsLoadingSession(false);
      return null;
    }

    try {
      const me = await getCurrentSessionUser(token);
      const mapped = mapSessionUser(me);
      setUser(mapped);
      setIsAuthenticated(true);
      return mapped;
    } catch {
      clearAuthToken();
      setUser(null);
      setIsAuthenticated(false);
      return null;
    } finally {
      setIsLoadingSession(false);
    }
  }, []);

  const login = useCallback(
    async (payload: LoginRequestPayload): Promise<SessionUser> => {
      const authResponse = await loginUser(payload);
      saveAuthToken(authResponse.token, Boolean(payload.rememberMe));
      const mapped = mapSessionUser(authResponse.user);
      setUser(mapped);
      setIsAuthenticated(true);
      return mapped;
    },
    []
  );

  // registro de una cuenta nueva: guarda el token y deja la sesión iniciada
  const register = useCallback(
    async (payload: RegisterRequestPayload): Promise<SessionUser> => {
      const authResponse = await registerUser(payload);
      saveAuthToken(authResponse.token, true);
      const mapped = mapSessionUser(authResponse.user);
      setUser(mapped);
      setIsAuthenticated(true);
      return mapped;
    },
    []
  );

  const logout = useCallback(() => {
    clearAuthToken();
    setUser(null);
    setIsAuthenticated(false);
  }, []);

  const hasPermission = useCallback(
    (permission?: string): boolean => {
      if (!permission) return true;
      if (!isAuthenticated || !user?.permissions) return false;
      return user.permissions.includes(permission);
    },
    [isAuthenticated, user]
  );

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated,
        isLoadingSession,
        user,
        login,
        register,
        logout,
        refreshSession,
        hasPermission,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}