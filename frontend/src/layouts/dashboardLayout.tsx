import { Box, Burger, Drawer, Flex } from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { Outlet, useNavigate } from 'react-router';
import logo from '../assets/PedestalLogo.svg';
import '../components/header/header.css';
import SideBar from '../components/sideBar/sideBar';
import { useViewportType } from '../hooks/useViewportType';

function DashboardLayout() {
  const viewport = useViewportType();
  const [drawerOpened, { toggle: toggleDrawer, close: closeDrawer }] = useDisclosure(false);
  const navigate = useNavigate();

  const isMobile = viewport === 'mobile';

  const handleGoTo = (path: string) => {
    closeDrawer();
    navigate(path);
  };

  return (
    <Flex
      direction={isMobile ? 'column' : 'row'}
      mih="100vh"
      w="100%"
      bg="light-dark(var(--mantine-color-gray-0), var(--mantine-color-dark-8))"
    >
      {/* Mobile: Header superior con logo a la izquierda y burger a la derecha */}
      {isMobile && (
        <>
          <header
            className={`header header--${viewport}`}
            style={{ position: 'sticky', top: 0, zIndex: 100 }}
          >
            <div className="logo">
              <img src={logo} alt="Logo de Pedestal" />
              <a
                href="/"
                onClick={(event) => {
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
            padding={0}
            classNames={{
              content: 'pedestalDrawerContent',
              header: 'pedestalDrawerHeader',
              title: 'pedestalDrawerTitle',
            }}
          >
            <SideBar inDrawer onNavigate={closeDrawer} />
          </Drawer>
        </>
      )}

      {/* Tablet y Desktop: SideBar fijo a la izquierda */}
      {!isMobile && (
        <Box
          component="aside"
          style={{ position: 'sticky', top: 0, height: '100vh', flexShrink: 0 }}
        >
          <SideBar />
        </Box>
      )}

      {/* Área derecha: Vistas hijas y paneles con <Splitter /> */}
      <Box
        component="main"
        style={{
          flex: 1,
          minWidth: 0,
          minHeight: isMobile ? 'calc(100vh - 10vh)' : '100vh',
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        <Outlet />
      </Box>
    </Flex>
  );
}

export default DashboardLayout;