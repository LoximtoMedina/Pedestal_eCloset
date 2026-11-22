// Importación de los componentes de react-router para redirigir y renderizar rutas hijas
import { Navigate, Outlet } from 'react-router';

// Definición de las propiedades que recibe la guarda de rutas protegidas
interface ProtectedRoutesProps {
  isAuthenticated: boolean; // Indica si el usuario tiene una sesión activa
  redirectTo?: string; // Ruta a la que se envía al usuario si no está autenticado (por defecto '/login')
}

// Componente encargado de bloquear el acceso a vistas privadas si no hay sesión iniciada
function ProtectedRoute({
  isAuthenticated,
  redirectTo = '/login',
}: ProtectedRoutesProps) {
  // Si el usuario no ha iniciado sesión, lo redirige a la vista de login reemplazando el historial
  if (!isAuthenticated) {
    return <Navigate to={redirectTo} replace />;
  }

  // Si sí está autenticado, permite renderizar la ruta hija correspondiente
  return <Outlet />;
}

export default ProtectedRoute;