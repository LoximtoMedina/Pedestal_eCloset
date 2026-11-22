/* ==========================================================================
   1. DEPENDENCIAS DE LAYOUT, CONTEXTO DE SESIÓN Y COMPONENTES
   ========================================================================== */
import { useEffect, useState } from 'react';
import { Outlet, useNavigate, useOutletContext } from 'react-router';
import { useAuth } from '../context/authContext';
import Header, { type HeaderNavItem, type HeaderSubItem } from '../components/header/header';
import Footer from '../components/footer/footer';

/* ==========================================================================
   2. CONTEXTO DE OUTLET PARA QUE CADA PÁGINA DEFINA SUS PESTAÑAS DEL HEADER
   ========================================================================== */
interface PublicLayoutOutletContext {
  setHeaderItems: (items: HeaderNavItem[]) => void;
}

export function usePublicHeaderItems(items: HeaderNavItem[]) {
  const context = useOutletContext<PublicLayoutOutletContext | undefined>();

  useEffect(() => {
    context?.setHeaderItems(items);
    return () => context?.setHeaderItems([]);
  }, [context, items]);
}

/* ==========================================================================
   3. LAYOUT PÚBLICO (HEADER + CONTENIDO DE PÁGINA + FOOTER)
   ========================================================================== */
function PublicLayout() {
  const { isAuthenticated, user, logoutMock } = useAuth();
  const navigate = useNavigate();
  const [headerItems, setHeaderItems] = useState<HeaderNavItem[]>([]);

  const profileMenuItems: HeaderSubItem[] = [
    { key: 'ecloset', label: 'Mi eCloset', to: '/ecloset' },
    { key: 'dashboard', label: 'Panel de control', to: '/dashboard' },
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
    <>
      <Header
        items={headerItems}
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

      <Outlet context={{ setHeaderItems } satisfies PublicLayoutOutletContext} />

      <Footer />
    </>
  );
}

export default PublicLayout;