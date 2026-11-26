import { useState, type MouseEvent } from 'react';
import { Burger, Drawer } from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { Outlet, useNavigate } from 'react-router';
import logo from '../../assets/PedestalLogo.svg';
import '../../components/header/header.css';
import SideBar, { type SideBarSection } from '../../components/sideBar/sideBar';
import { useAuth } from '../../context/authContext';
import type { LayoutNavOutletContext } from '../../hooks/useLayoutNavItems';
import { useViewportType } from '../../hooks/useViewportType';
import './dashboardLayout.css';

function DashboardLayout() {
  const viewport = useViewportType();
  const [drawerOpened, { toggle: toggleDrawer, close: closeDrawer }] = useDisclosure(false);
  const navigate = useNavigate();
  const { user, logoutMock } = useAuth();
  const [sidebarItems, setSidebarItems] = useState<SideBarSection[]>([]);

  const isMobile = viewport === 'mobile';

  const handleGoTo = (path: string) => {
    closeDrawer();
    navigate(path);
  };

  const handleLogout = () => {
    logoutMock();
    navigate('/login');
  };

  const sideBarUser = user
    ? {
        name: `${user.primerNombre ?? ''} ${user.primerApellido ?? ''}`.trim() || undefined,
        email: user.correo,
        avatarSrc: user.avatarSrc,
      }
    : null;

  return (
    <div className={`dashboard-layout ${isMobile ? 'dashboard-layout--mobile' : ''}`}>
      {isMobile && (
        <>
          <header className={`header header--${viewport} dashboard-mobile-header`}>
            <div className="logo">
              <img src={logo} alt="Logo de Pedestal" />
              <a
                href="/"
                onClick={(event: MouseEvent<HTMLAnchorElement>) => {
                  event.preventDefault();
                  handleGoTo('/');
                }}
              >
                <h1>PEDESTAL</h1>
              </a>
            </div>

            <Burger
              opened={drawerOpened}
              onClick={toggleDrawer}
              aria-label="Abrir menú de navegación"
              classNames={{
                root: 'mobileBurger',
                burger: 'mobileBurgerLine',
              }}
            />
          </header>

          <Drawer
            opened={drawerOpened}
            onClose={closeDrawer}
            title="PEDESTAL"
            position="right"
            size="80%"
            classNames={{
              content: 'pedestalDrawerContent',
              header: 'pedestalDrawerHeader',
              title: 'pedestalDrawerTitle',
              body: 'dashboard-drawer-body',
            }}
          >
            <SideBar
              items={sidebarItems}
              user={sideBarUser}
              inDrawer
              onNavigate={closeDrawer}
              onLogoutClick={handleLogout}
            />
          </Drawer>
        </>
      )}

      {!isMobile && (
        <aside className="dashboard-sidebar-aside">
          <SideBar
            items={sidebarItems}
            user={sideBarUser}
            onLogoutClick={handleLogout}
          />
        </aside>
      )}

      <main className="dashboard-main">
        <Outlet context={{ setNavItems: setSidebarItems } satisfies LayoutNavOutletContext<SideBarSection>} />
      </main>
    </div>
  );
}

export default DashboardLayout;