/* ==========================================================================
   1. DEPENDENCIAS DE ENRUTAMIENTO Y CONTEXTO DE SESIÓN
   ========================================================================== */
import { Navigate, Outlet } from 'react-router';
import { useAuth } from '../hooks/authHook';

/* ==========================================================================
   2. TIPOS Y CONTRATO DE PROPS
   ========================================================================== */
interface ProtectedRoutesProps {
  redirectTo?: string;
  requiredPermission?: string;
}

/* ==========================================================================
   3. GUARDA DE RUTAS PRIVADAS (SESIÓN Y PERMISO OPCIONAL)
   ========================================================================== */
function ProtectedRoute({
  redirectTo = '/login',
  requiredPermission,
}: ProtectedRoutesProps) {
  const { isAuthenticated, hasPermission } = useAuth();

  // Bloquea el acceso si no hay sesión activa
  if (!isAuthenticated) {
    return <Navigate to={redirectTo} replace />;
  }

  // Si la ruta exige un permiso específico y el usuario no lo tiene, redirige al inicio
  if (requiredPermission && !hasPermission(requiredPermission)) {
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
}

export default ProtectedRoute;