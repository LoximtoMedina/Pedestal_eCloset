/* ==========================================================================
   1. DEPENDENCIAS DE UI, ENRUTAMIENTO Y ESTILOS
   ========================================================================== */
import { Avatar, Burger, Drawer, Menu, Stack, UnstyledButton } from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { useNavigate } from 'react-router';
import { useViewportType } from '../../hooks/useViewportType';
import './header.css';
import logo from '../../assets/PedestalLogo.svg';

/* ==========================================================================
   2. TIPOS Y CONTRATO DE PROPS
   ========================================================================== */
export interface HeaderSubItem {
  key: string;
  label: string;
  to?: string;
  href?: string;
  onClick?: () => void;
}

export interface HeaderNavItem {
  key: string;
  label: string;
  to?: string;
  href?: string;
  children?: HeaderSubItem[];
}

export interface HeaderUserInfo {
  name?: string;
  avatarSrc?: string;
}

interface HeaderProps {
  items?: HeaderNavItem[];
  maxVisibleItems?: number;
  showAuthButtons?: boolean;
  showSessionMenu?: boolean;
  user?: HeaderUserInfo | null;
  profileMenuItems?: HeaderSubItem[];
  compact?: boolean;
  onLoginClick?: () => void;
  onRegisterClick?: () => void;
}

/* ==========================================================================
   3. COMPONENTE HEADER REUTILIZABLE
   ========================================================================== */
function Header({
  items = [],
  maxVisibleItems = 3,
  showAuthButtons = true,
  showSessionMenu = false,
  user = null,
  profileMenuItems = [],
  compact = false,
  onLoginClick,
  onRegisterClick,
}: HeaderProps) {
  const viewport = useViewportType();
  const [drawerOpened, { toggle: toggleDrawer, close: closeDrawer }] = useDisclosure(false);
  const navigate = useNavigate();

  const isMobile = viewport === 'mobile';

  /* --------------------------------------------------------------------------
     Agrupación automática: máximo 3 pestañas visibles + 4ta pestaña "Más"
     -------------------------------------------------------------------------- */
  const visibleItems: HeaderNavItem[] =
    items.length > maxVisibleItems
      ? [
          ...items.slice(0, maxVisibleItems),
          {
            key: 'more-items',
            label: 'Más',
            children: items.slice(maxVisibleItems).flatMap((item) =>
              item.children && item.children.length > 0
                ? item.children
                : [{ key: item.key, label: item.label, to: item.to, href: item.href }]
            ),
          },
        ]
      : items;

  /* --------------------------------------------------------------------------
     Helpers de navegación unificada (rutas internas, anclas y URLs externas)
     -------------------------------------------------------------------------- */
  const handleNavigate = (target?: { to?: string; href?: string; onClick?: () => void }) => {
    if (!target) return;

    target.onClick?.();

    if (target.to) {
      navigate(target.to);
    } else if (target.href) {
      if (target.href.startsWith('#')) {
        const element = document.querySelector(target.href);
        element?.scrollIntoView({ behavior: 'smooth' });
      } else {
        window.location.assign(target.href);
      }
    }
  };

  const handleGoTo = (path: string) => {
    closeDrawer();
    navigate(path);
  };

  /* --------------------------------------------------------------------------
     Renderizado
     -------------------------------------------------------------------------- */
  return (
    <header className={`header header--${viewport} ${compact ? 'header--compact' : ''}`}>
      {/* Izquierda: Logo + Marca */}
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

      {/* Centro (Tablet / Desktop): Máximo 3 pestañas + "Más" si hay excedente */}
      {!isMobile && visibleItems.length > 0 && (
        <nav aria-label="Navegación principal">
          {visibleItems.map((item) => {
            const hasSubmenu = Boolean(item.children && item.children.length > 0);

            if (hasSubmenu && item.children) {
              return (
                <Menu
                  key={item.key}
                  trigger="hover"
                  openDelay={100}
                  closeDelay={150}
                  classNames={{
                    dropdown: 'pedestalMenuDropdown',
                    item: 'pedestalMenuItem',
                  }}
                >
                  <Menu.Target>
                    <UnstyledButton className="navLink">{item.label}</UnstyledButton>
                  </Menu.Target>

                  <Menu.Dropdown>
                    {item.children.map((subItem) => (
                      <Menu.Item
                        key={subItem.key}
                        component={subItem.href ? 'a' : 'button'}
                        href={subItem.href}
                        onClick={(event: React.MouseEvent<HTMLElement>) => {
                          if (subItem.to) {
                            event.preventDefault();
                            handleNavigate(subItem);
                          } else if (!subItem.href) {
                            subItem.onClick?.();
                          }
                        }}
                      >
                        {subItem.label}
                      </Menu.Item>
                    ))}
                  </Menu.Dropdown>
                </Menu>
              );
            }

            return (
              <a
                key={item.key}
                href={item.href ?? item.to ?? '#'}
                className="navLink"
                onClick={(event) => {
                  if (item.to || item.href?.startsWith('#')) {
                    event.preventDefault();
                    handleNavigate(item);
                  }
                }}
              >
                {item.label}
              </a>
            );
          })}
        </nav>
      )}

      {/* Derecha (Tablet / Desktop): Avatar + flecha (con sesión) o Botones Auth (sin sesión) */}
      {!isMobile && (
        <div className="sessionButtons">
          {showSessionMenu ? (
            <Menu
              position="bottom-end"
              offset={8}
              classNames={{
                dropdown: 'pedestalMenuDropdown',
                item: 'pedestalMenuItem',
              }}
            >
              <Menu.Target>
                <UnstyledButton
                  className="sessionAvatarTrigger"
                  aria-label="Abrir menú de usuario"
                >
                  <Avatar
                    src={user?.avatarSrc || undefined}
                    name={user?.name}
                    alt={user?.name ?? 'Usuario'}
                    radius="xl"
                    size={34}
                    color="dark"
                  />
                  <svg
                    className="sessionAvatarChevron"
                    width="14"
                    height="14"
                    viewBox="0 0 16 16"
                    fill="none"
                    aria-hidden="true"
                  >
                    <path
                      d="M3 5.5L8 11L13 5.5H3Z"
                      stroke="currentColor"
                      strokeWidth="1.6"
                      strokeLinejoin="round"
                    />
                  </svg>
                </UnstyledButton>
              </Menu.Target>

              <Menu.Dropdown>
                {profileMenuItems.map((option) => (
                  <Menu.Item key={option.key} onClick={() => handleNavigate(option)}>
                    {option.label}
                  </Menu.Item>
                ))}
              </Menu.Dropdown>
            </Menu>
          ) : (
            showAuthButtons && (
              <>
                <button
                  type="button"
                  onClick={() => (onLoginClick ? onLoginClick() : navigate('/login'))}
                >
                  Iniciar Sesión
                </button>
                <button
                  type="button"
                  onClick={() => (onRegisterClick ? onRegisterClick() : navigate('/signup'))}
                >
                  Registrarse
                </button>
              </>
            )
          )}
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
              {/* En móvil mostramos todos los enlaces planos (sin colapsar en "Más") */}
              {items.map((item) => {
                if (item.children && item.children.length > 0) {
                  return (
                    <Stack key={item.key} gap="xs">
                      <span className="mobileNavLink">{item.label}</span>
                      {item.children.map((subItem) => (
                        <a
                          key={subItem.key}
                          href={subItem.href ?? subItem.to ?? '#'}
                          className="mobileNavLink"
                          onClick={(event) => {
                            if (subItem.to || subItem.href?.startsWith('#')) {
                              event.preventDefault();
                            }
                            closeDrawer();
                            handleNavigate(subItem);
                          }}
                        >
                          {subItem.label}
                        </a>
                      ))}
                    </Stack>
                  );
                }

                return (
                  <a
                    key={item.key}
                    href={item.href ?? item.to ?? '#'}
                    className="mobileNavLink"
                    onClick={(event) => {
                      if (item.to || item.href?.startsWith('#')) {
                        event.preventDefault();
                      }
                      closeDrawer();
                      handleNavigate(item);
                    }}
                  >
                    {item.label}
                  </a>
                );
              })}

              {/* Opciones de usuario o botones de sesión en móvil */}
              {showSessionMenu ? (
                <Stack gap="xs" className="mobileUserSection">
                  <div className="mobileUserHeader">
                    <Avatar
                      src={user?.avatarSrc || undefined}
                      name={user?.name}
                      alt={user?.name ?? 'Usuario'}
                      radius="xl"
                      size={32}
                      color="dark"
                    />
                    <span>{user?.name ?? 'Mi cuenta'}</span>
                  </div>

                  {profileMenuItems.map((option) => (
                    <button
                      key={option.key}
                      type="button"
                      className="mobileProfileOptionBtn"
                      onClick={() => {
                        closeDrawer();
                        handleNavigate(option);
                      }}
                    >
                      {option.label}
                    </button>
                  ))}
                </Stack>
              ) : (
                showAuthButtons && (
                  <div className="mobileSessionButtons">
                    <button
                      type="button"
                      onClick={() => {
                        if (onLoginClick) {
                          onLoginClick()
                        } else {
                          navigate('/login');
                        }
                      }}
                    >
                      Iniciar Sesión
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        if (onRegisterClick) {
                          onRegisterClick();
                        } else {
                          navigate('/signup');
                        }
                      }}
                    >
                      Registrarse
                    </button>
                  </div>
                )
              )}
            </Stack>
          </Drawer>
        </>
      )}
    </header>
  );
}

export default Header;