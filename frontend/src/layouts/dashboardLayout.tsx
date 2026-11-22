// Importación de Outlet para renderizar la vista de dashboard correspondiente
import { Outlet } from 'react-router';
// Importación del Header (puedes mantenerlo o usar una navegación específica del panel)
import Header from '../components/header/header';

// Marco general para las vistas de dashboard (sin el Footer comercial de la tienda)
function DashboardLayout() {
  return (
    <div className="dashboardLayout">
      <Header />

      {/* Contenedor principal donde se cargará StoreDashboard, AreaDashboard o NationalDashboard */}
      <main className="dashboardContent">
        <Outlet />
      </main>
    </div>
  );
}

export default DashboardLayout;