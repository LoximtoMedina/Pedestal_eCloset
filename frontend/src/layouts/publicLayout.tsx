// Importación de Outlet para renderizar la ruta hija activa dentro de este layout
import { Outlet } from 'react-router';
// Importación de los componentes persistentes de la parte pública/tienda
import Header from '../components/header/header';
import Footer from '../components/footer/footer';

// Marco general para las páginas públicas: mantiene Header arriba y Footer abajo
function PublicLayout() {
  return (
    <div className="publicLayout">
      {/* Encabezado compartido en todas las rutas que usen este layout */}
      <Header />

      {/* Aquí React Router inyecta la página actual (Home, Login, SignUp, etc.) */}
      <Outlet />

      {/* Pie de página compartido */}
      <Footer />
    </div>
  );
}

export default PublicLayout;