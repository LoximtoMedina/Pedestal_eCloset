import { createContext } from 'react';
import type {
  LoginRequestPayload,
  SessionUserData,
} from '../services/authService';

export interface SessionUser extends SessionUserData {
  avatarSrc?: string;
}

export interface AuthContextValue {
  isAuthenticated: boolean;
  isLoadingSession: boolean;
  user: SessionUser | null;
  login: (payload: LoginRequestPayload) => Promise<SessionUser>;
  logout: () => void;
  refreshSession: () => Promise<SessionUser | null>;
  hasPermission: (permission?: string) => boolean;
}

export const AuthContext = createContext<AuthContextValue | undefined>(
  undefined
);