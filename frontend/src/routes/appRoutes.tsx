/* ==========================================================================
   1. DEPENDENCIAS DE ENRUTAMIENTO Y CONTEXTO DE SESIÓN
   ========================================================================== */
import { Routes, Route, Navigate, useNavigate } from 'react-router';
import { useAuth, getDashboardRoute } from '../context/authContext';

/* ==========================================================================
   2. LAYOUTS, GUARDAS DE RUTA Y VISTAS
   ========================================================================== */
import PublicLayout from '../layouts/publicLayout';
import DashboardLayout from '../layouts/dashboardLayout';
import ProtectedRoute from './protectedRoutes';
import Home from '../pages/home/home';
import Login from '../pages/auth/login/login';
import SignUp from '../pages/auth/signUp/signUp';

// Descomenta e importa tus vistas conforme las vayas conectando:
import Catalog from '../pages/shop/catalog/catalog';
import TryOn from '../pages/ecloset/tryOn/tryOn';
import Profile from '../pages/user/profile/profile';
import MyOrders from '../pages/user/myOrders/myOrders';
import StoreDashboard from '../pages/dashboards/storeDashboard/storeDashboard';
import AreaDashboard from '../pages/dashboards/areaDashboard/areaDashboard';
import NationalDashboard from '../pages/dashboards/nationalDashboard/nationalDashboard';
import RolesAdmin from '../pages/admin/roles/roles';

/* ==========================================================================
   3. ENRUTADOR PRINCIPAL DE LA APLICACIÓN
   ========================================================================== */
function AppRoutes() {
  const { isAuthenticated, user, loginMock } = useAuth();
  const navigate = useNavigate();
  const dashboardTarget = getDashboardRoute(user?.role);

  return (
    <Routes>
      {/* Rutas de autenticación (redirigen si ya existe sesión activa) */}
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
        <Route path="/shop/catalog" element={<Catalog />} />
      </Route>

      {/* Rutas privadas protegidas (requieren sesión iniciada) */}
      <Route element={<ProtectedRoute />}>
        {/* Vistas de usuario / eCloset */}
        <Route element={<PublicLayout />}>
          <Route path="/user/profile" element={<Profile />} />
          <Route path="/user/my-orders" element={<MyOrders />} />
          <Route path="/ecloset/try-on" element={<TryOn />} />
        </Route>

        {/* Dashboards y módulos internos con DashboardLayout */}
        <Route element={<DashboardLayout />}>
          <Route path="/dashboard" element={<Navigate to={dashboardTarget} replace />} />
          <Route path="/dashboards/store" element={<StoreDashboard />} />
          <Route path="/dashboards/area" element={<AreaDashboard />} />
          <Route path="/dashboards/national" element={<NationalDashboard />} />
          <Route path="/admin/roles" element={<RolesAdmin />} />
        </Route>
      </Route>

      {/* Redirección por defecto ante rutas inexistentes */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default AppRoutes;