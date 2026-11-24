import type { ComponentType } from 'react';
import {
  IconAdjustments,
  IconBuildingStore,
  IconCalendarStats,
  IconChartBar,
  IconChevronRight,
  IconGauge,
  IconLogout,
  IconPackage,
  IconShoppingBag,
  IconTag,
  IconUser,
  IconUsers,
} from '@tabler/icons-react';
import {
  Avatar,
  Box,
  Code,
  Group,
  Menu,
  NavLink,
  ScrollArea,
  Text,
  UnstyledButton,
} from '@mantine/core';
import { useLocation, useNavigate } from 'react-router';
import logo from '../../assets/PedestalLogo.svg';
import './sideBar.css';

export interface SideBarSubLink {
  label: string;
  link: string;
}

export interface SideBarSection {
  label: string;
  icon: ComponentType<{ size?: number | string; stroke?: number }>;
  link?: string;
  initiallyOpened?: boolean;
  links?: SideBarSubLink[];
}

interface SideBarProps {
  inDrawer?: boolean;
  onNavigate?: () => void;
}

const pedestalNavData: SideBarSection[] = [
  {
    label: 'Inicio',
    icon: IconGauge,
    link: '/dashboards',
  },
  {
    label: 'Dashboards',
    icon: IconChartBar,
    initiallyOpened: true,
    links: [
      { label: 'Tienda', link: '/dashboards/store' },
      { label: 'Área', link: '/dashboards/area' },
      { label: 'Nacional', link: '/dashboards/national' },
    ],
  },
  {
    label: 'Inventario',
    icon: IconPackage,
    link: '/inventory',
  },
  {
    label: 'Punto de Venta (POS)',
    icon: IconBuildingStore,
    link: '/pos',
  },
  {
    label: 'Compras',
    icon: IconShoppingBag,
    link: '/purchases',
  },
  {
    label: 'Promociones',
    icon: IconTag,
    link: '/promotions',
  },
  {
    label: 'Recursos Humanos',
    icon: IconUsers,
    link: '/hr',
  },
  {
    label: 'eCloset',
    icon: IconCalendarStats,
    link: '/ecloset',
  },
  {
    label: 'Administración',
    icon: IconAdjustments,
    link: '/admin',
  },
];

function NavSectionItem({
  item,
  currentPath,
  onSelectLink,
}: {
  item: SideBarSection;
  currentPath: string;
  onSelectLink: (path: string) => void;
}) {
  const Icon = item.icon;
  const hasSubLinks = Array.isArray(item.links) && item.links.length > 0;
  const hasActiveChild = hasSubLinks
    ? item.links!.some((sub) => currentPath === sub.link)
    : false;

  if (!hasSubLinks) {
    return (
      <NavLink
        label={item.label}
        leftSection={<Icon size={18} stroke={1.6} />}
        active={item.link ? currentPath === item.link : false}
        onClick={() => {
          if (item.link) {
            onSelectLink(item.link);
          }
        }}
        className="pedestalSidebarNavItem"
      />
    );
  }

  return (
    <NavLink
      label={item.label}
      leftSection={<Icon size={18} stroke={1.6} />}
      childrenOffset={28}
      defaultOpened={Boolean(item.initiallyOpened) || hasActiveChild}
      className="pedestalSidebarNavItem"
    >
      {item.links!.map((sub) => (
        <NavLink
          key={sub.link}
          label={sub.label}
          active={currentPath === sub.link}
          onClick={() => onSelectLink(sub.link)}
          className="pedestalSidebarSubNavItem"
        />
      ))}
    </NavLink>
  );
}

function SideBar({ inDrawer = false, onNavigate }: SideBarProps) {
  const navigate = useNavigate();
  const location = useLocation();

  const handleSelectLink = (path: string) => {
    onNavigate?.();
    navigate(path);
  };

  const handleGoHome = (event: React.MouseEvent<HTMLAnchorElement>) => {
    event.preventDefault();
    onNavigate?.();
    navigate('/');
  };

  return (
    <nav
      className={`pedestalSidebar ${inDrawer ? 'pedestalSidebar--inDrawer' : ''}`}
      aria-label="Navegación del panel"
    >
      {!inDrawer && (
        <div className="pedestalSidebarHeader">
          <Group justify="space-between">
            <a href="/" className="pedestalSidebarBrandLink" onClick={handleGoHome}>
              <img src={logo} alt="Logo de Pedestal" className="pedestalSidebarBrandLogo" />
              <h1 className="pedestalSidebarBrandTitle">PEDESTAL</h1>
            </a>
            <Code fw={700}>v1.0</Code>
          </Group>
        </div>
      )}

      <ScrollArea className="pedestalSidebarLinks">
        <div className="pedestalSidebarLinksInner">
          {pedestalNavData.map((item) => (
            <NavSectionItem
              key={item.label}
              item={item}
              currentPath={location.pathname}
              onSelectLink={handleSelectLink}
            />
          ))}
        </div>
      </ScrollArea>

      <div className="pedestalSidebarFooter">
        <Menu position="top-end" withArrow shadow="md">
          <Menu.Target>
            <UnstyledButton className="pedestalSidebarUserBtn">
              <Group gap="sm" wrap="nowrap">
                <Avatar radius="xl" size="md" color="dark">
                  P
                </Avatar>
                <Box style={{ flex: 1, minWidth: 0 }}>
                  <Text size="sm" fw={500} truncate>
                    Usuario Pedestal
                  </Text>
                  <Text c="dimmed" size="xs" truncate>
                    usuario@pedestal.com
                  </Text>
                </Box>
                <IconChevronRight size={15} stroke={1.6} />
              </Group>
            </UnstyledButton>
          </Menu.Target>

          <Menu.Dropdown>
            <Menu.Item
              leftSection={<IconUser size={15} />}
              onClick={() => handleSelectLink('/profile')}
            >
              Mi perfil
            </Menu.Item>
            <Menu.Divider />
            <Menu.Item
              color="red"
              leftSection={<IconLogout size={15} />}
              onClick={() => handleSelectLink('/login')}
            >
              Cerrar sesión
            </Menu.Item>
          </Menu.Dropdown>
        </Menu>
      </div>
    </nav>
  );
}

export default SideBar;