import { Burger, Drawer, Menu, Stack, UnstyledButton } from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { useNavigate } from 'react-router';
import { useViewportType } from '../../hooks/useViewportType';
import './header.css';
import logo from '../../assets/PedestalLogo.svg';

interface NavItem {
  label: string;
  key: string;
  href?: string;
}

const navItems: NavItem[] = [
  { label: 'Ofertas', key: 'offers', href: '#offers' },
  { label: 'Sobre Nosotros', key: 'aboutUs', href: '#about' },
  { label: 'Contáctanos', key: 'contactUs', href: '#contact' },
];

function Header() {
  const viewport = useViewportType();
  const [drawerOpened, { toggle: toggleDrawer, close: closeDrawer }] = useDisclosure(false);
  const navigate = useNavigate();

  const isMobile = viewport === 'mobile';

  // Función auxiliar para navegar y cerrar el Drawer en móvil al mismo tiempo
  const handleGoTo = (path: string) => {
    closeDrawer();
    navigate(path);
  };

  return (
    <header className={`header header--${viewport}`}>
      {/* Sección izquierda: Logo + Nombre */}
      <div className="logo">
        <img src={logo} alt="Logo" />
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

      {/* Tablet y Desktop: Navegación central con Mantine */}
      {!isMobile && (
        <nav>
          {navItems.map((item) => (
            <a key={item.key} href={item.href} className="navLink">
              {item.label}
            </a>
          ))}

          <Menu
            trigger="hover"
            openDelay={100}
            closeDelay={150}
            classNames={{
              dropdown: 'pedestalMenuDropdown',
              item: 'pedestalMenuItem',
            }}
          >
            <Menu.Target>
              <UnstyledButton className="navLink">Más</UnstyledButton>
            </Menu.Target>

            <Menu.Dropdown>
              <Menu.Item component="a" href="#new">
                Novedades
              </Menu.Item>
              <Menu.Item component="a" href="#collections">
                Colecciones
              </Menu.Item>
            </Menu.Dropdown>
          </Menu>
        </nav>
      )}

      {/* Tablet y Desktop: Botones de sesión */}
      {!isMobile && (
        <div className="sessionButtons">
          <button type="button" onClick={() => navigate('/login')}>
            Iniciar Sesión
          </button>
          <button type="button" onClick={() => navigate('/signup')}>
            Registrarse
          </button>
        </div>
      )}

      {/* Mobile: Burger + Drawer */}
      {isMobile && (
        <>
          <Burger
            opened={drawerOpened}
            onClick={toggleDrawer}
            aria-label="Abrir menú"
            classNames={{
              root: 'mobileBurger',
              burger: 'mobileBurgerLine',
            }}
          />

          <Drawer
            opened={drawerOpened}
            onClose={closeDrawer}
            title="PEDESTAL"
            position="right"
            size="75%"
            classNames={{
              content: 'pedestalDrawerContent',
              header: 'pedestalDrawerHeader',
              title: 'pedestalDrawerTitle',
            }}
          >
            <Stack gap="md" className="mobileNavStack">
              {navItems.map((item) => (
                <a
                  key={item.key}
                  href={item.href}
                  className="mobileNavLink"
                  onClick={closeDrawer}
                >
                  {item.label}
                </a>
              ))}

              <a href="#new" className="mobileNavLink" onClick={closeDrawer}>
                Novedades
              </a>
              <a href="#collections" className="mobileNavLink" onClick={closeDrawer}>
                Colecciones
              </a>

              <div className="mobileSessionButtons">
                <button type="button" onClick={() => handleGoTo('/login')}>
                  Iniciar Sesión
                </button>
                <button type="button" onClick={() => handleGoTo('/signup')}>
                  Registrarse
                </button>
              </div>
            </Stack>
          </Drawer>
        </>
      )}
    </header>
  );
}

export default Header;