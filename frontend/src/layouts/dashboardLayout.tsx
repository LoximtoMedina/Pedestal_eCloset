/* ==========================================================================
   1. DEPENDENCIAS DE LAYOUT, CONTEXTO DE SESIÓN Y COMPONENTES
   ========================================================================== */
import { Outlet, useNavigate, useOutletContext } from 'react-router';
import { useAuth } from '../context/authContext';
import Header, { type HeaderSubItem } from '../components/header/header';

/* ==========================================================================
   3. LAYOUT DE DASHBOARDS (HEADER () + + FOOTER)
   ========================================================================== */
function DashboardLayout() {
  const { isAuthenticated, user, logoutMock, hasPermission } = useAuth();
  const navigate = useNavigate();


  const profileMenuItems: HeaderSubItem[] = [
    ...(hasPermission('ecloset.access')
      ? [{ key: 'user', label: 'Mi Usuario', to: '/user/profile' }]
      : []),
    ...(hasPermission('ecloset.access')
      ? [{ key: 'ecloset', label: 'Mi eCloset', to: '/ecloset/try-on' }]
      : []),
    ...(hasPermission('dashboard.view')
      ? [{ key: 'dashboard', label: 'Panel de control', to: '/dashboard' }]
      : []),
    {
      key: 'logout',
      label: 'Cerrar sesión',
      onClick: () => {
        logoutMock();
        navigate('/');
      },
    },
  ];

  return (
    <div className="dashboardLayout">
      <Header 
        showAuthButtons={!isAuthenticated}
        showSessionMenu={isAuthenticated}
        user={
          user
            ? {
                name: `${user.primerNombre} ${user.primerApellido}`,
                avatarSrc: user.avatarSrc,
              }
            : null
        }
        profileMenuItems={profileMenuItems}
      />

      {/* Contenedor principal donde se cargará StoreDashboard, AreaDashboard o NationalDashboard */}
      <main className="dashboardContent">
        <Outlet />
      </main>
    </div>
  );
}

export default DashboardLayout;