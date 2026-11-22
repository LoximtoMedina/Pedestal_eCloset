// Importación de los componentes y hook de navegación de react-router
import { Routes, Route, Navigate, useNavigate } from 'react-router';
// Importación de los layouts generales para separar vistas públicas y paneles
import PublicLayout from '../layouts/publicLayout';
import DashboardLayout from '../layouts/dashboardLayout';
// Importación de la guarda para proteger las rutas privadas
import ProtectedRoute from './protectedRoutes';
// Importación de las pantallas principales y de autenticación
import Home from '../pages/home/home';
import Login from '../pages/auth/login/login';
import SignUp from '../pages/auth/signUp/signUp';

// Definición de las props que recibe el enrutador principal
interface AppRoutesProps {
  isAuthenticated: boolean; // Estado global de sesión que se pasa a las rutas protegidas
}

// Componente que centraliza todas las rutas públicas y privadas de la aplicación
function AppRoutes({ isAuthenticated }: AppRoutesProps) {
  // Hook para navegar de forma programática entre rutas (ej. al enviar formularios)
  const navigate = useNavigate();

  return (
    <Routes>
      {/* Rutas de autenticación sin PublicLayout (pantalla limpia, sin Header ni Footer) */}
      <Route
        path="/login"
        element={
          <Login
            // Si el usuario hace clic en "Registrarse", lo manda a /signup
            onRegisterClick={() => navigate('/signup')}
            // Al enviar el formulario de login, lo redirige al inicio (aquí irá la llamada a la API)
            onSubmit={() => {
              navigate('/');
            }}
          />
        }
      />

      <Route
        path="/signup"
        element={
          <SignUp
            // Si ya tiene cuenta y hace clic en "Iniciar Sesión", lo manda a /login
            onLoginClick={() => navigate('/login')}
            // Al completar el registro, lo lleva al login para que inicie sesión
            onSubmit={() => {
              navigate('/login');
            }}
          />
        }
      />

      {/* Rutas públicas envueltas en PublicLayout (Header + vista + Footer) */}
      <Route element={<PublicLayout />}>
        {/* Ruta raíz pública (landing / inicio de la tienda) */}
        <Route path="/" element={<Home />} />
      </Route>

      {/* Grupo de rutas protegidas: solo accesibles si isAuthenticated es true */}
      <Route element={<ProtectedRoute isAuthenticated={isAuthenticated} />}>
        <Route element={<DashboardLayout />}>
          {/* Aquí irán las rutas privadas / dashboards */}
        </Route>
      </Route>

      {/* Ruta comodín: cualquier URL que no exista redirige al inicio */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default AppRoutes;