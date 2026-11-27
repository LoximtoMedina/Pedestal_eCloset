/* ==========================================================================
1. DEPENDENCIAS DE LAYOUT, CONTEXTO DE SESIÓN Y COMPONENTES
   ========================================================================== */
import { useState } from 'react';
import { Outlet, useNavigate } from 'react-router';
import { useAuth } from '../../hooks/authHook';
import Header, { type HeaderNavItem, type HeaderSubItem } from '../../components/header/header';
import Footer from '../../components/footer/footer';
import { type LayoutNavOutletContext } from '../../hooks/useLayoutNavItems';

/* ==========================================================================
2. LAYOUT PÚBLICO (HEADER + CONTENIDO DE PÁGINA + FOOTER)
   ========================================================================== */
function PublicLayout() {
  const { isAuthenticated, user, logout, hasPermission } = useAuth();
  const navigate = useNavigate();
  const [headerItems, setHeaderItems] = useState<HeaderNavItem[]>([]);

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
        logout();
        navigate('/');
      },
    },
  ];

  return (
    <>
      <Header
        items={headerItems}
        showAuthButtons={!isAuthenticated}
        showSessionMenu={isAuthenticated}
        user={
          user
            ? {
                name: `${user.firstName} ${user.firstSurname}`,
                avatarSrc: user.avatarSrc,
              }
            : null
        }
        profileMenuItems={profileMenuItems}
      />

      <Outlet context={{ setNavItems: setHeaderItems } satisfies LayoutNavOutletContext<HeaderNavItem>} />

      <Footer />
    </>
  );
}

export default PublicLayout;