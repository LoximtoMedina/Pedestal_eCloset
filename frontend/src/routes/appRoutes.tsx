/* ==========================================================================
   1. DEPENDENCIAS DE ENRUTAMIENTO Y CONTEXTO DE SESIÓN
   ========================================================================== */
import { Routes, Route, Navigate, useNavigate } from 'react-router';
import { useAuth } from '../context/authContext';

/* ==========================================================================
   2. LAYOUTS, GUARDAS DE RUTA Y VISTAS
   ========================================================================== */
import PublicLayout from '../layouts/publicLayout';
import DashboardLayout from '../layouts/dashboardLayout';
import ProtectedRoute from './protectedRoutes';
import Home from '../pages/home/home';
import Login from '../pages/auth/login/login';
import SignUp from '../pages/auth/signUp/signUp';

/* ==========================================================================
   3. ENRUTADOR PRINCIPAL DE LA APLICACIÓN
   --------------------------------------------------------------------------
   Centraliza el estado de sesión desde AuthContext y organiza las rutas en:
   - Rutas de autenticación (/login, /signup) sin layout público.
   - Rutas públicas con PublicLayout.
   - Rutas privadas protegidas por ProtectedRoute y envueltas en DashboardLayout.
   ========================================================================== */
function AppRoutes() {
  const { isAuthenticated, loginMock } = useAuth();
  const navigate = useNavigate();

  return (
    <Routes>
      {/* Rutas de autenticación (redirigen a "/" si ya hay sesión activa) */}
      <Route
        path="/login"
        element={
          isAuthenticated ? (
            <Navigate to="/" replace />
          ) : (
            <Login
              onRegisterClick={() => navigate('/signup')}
              onSubmit={({ email }) => {
                loginMock({ identifier: email });
                navigate('/');
              }}
            />
          )
        }
      />

      <Route
        path="/signup"
        element={
          isAuthenticated ? (
            <Navigate to="/" replace />
          ) : (
            <SignUp
              onLoginClick={() => navigate('/login')}
              onSubmit={(data) => {
                loginMock({
                  correo: data.correo,
                  nombreUsuario: data.nombreUsuario,
                  primerNombre: data.primerNombre,
                  primerApellido: data.primerApellido,
                });
                navigate('/');
              }}
            />
          )
        }
      />

      {/* Rutas públicas con Header y Footer */}
      <Route element={<PublicLayout />}>
        <Route path="/" element={<Home />} />
      </Route>

      {/* Rutas privadas protegidas con DashboardLayout */}
      <Route element={<ProtectedRoute isAuthenticated={isAuthenticated} />}>
        <Route element={<DashboardLayout />}>
          {/* Aquí se agregarán las rutas de dashboards y módulos internos */}
        </Route>
      </Route>

      {/* Redirección por defecto ante rutas inexistentes */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default AppRoutes;