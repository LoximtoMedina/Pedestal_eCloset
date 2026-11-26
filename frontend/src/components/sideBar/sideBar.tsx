import type { ComponentType, MouseEvent } from 'react';
import {
  IconChevronRight,
  IconLogout,
  IconUser,
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
  key?: string;
  label: string;
  link: string;
}

export interface SideBarSection {
  key?: string;
  label: string;
  icon: ComponentType<{ size?: number | string; stroke?: number }>;
  link?: string;
  initiallyOpened?: boolean;
  links?: SideBarSubLink[];
}

export interface SideBarUserInfo {
  name?: string;
  email?: string;
  avatarSrc?: string;
}

export interface SideBarProps {
  items?: SideBarSection[];
  user?: SideBarUserInfo | null;
  inDrawer?: boolean;
  onNavigate?: () => void;
  onProfileClick?: () => void;
  onLogoutClick?: () => void;
}

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
      {item.links!.map((sub, index) => (
        <NavLink
          key={sub.key ?? `${sub.link}-${index}`}
          label={sub.label}
          active={currentPath === sub.link}
          onClick={() => onSelectLink(sub.link)}
          className="pedestalSidebarSubNavItem"
        />
      ))}
    </NavLink>
  );
}

function SideBar({
  items = [],
  user = null,
  inDrawer = false,
  onNavigate,
  onProfileClick,
  onLogoutClick,
}: SideBarProps) {
  const navigate = useNavigate();
  const location = useLocation();

  const handleSelectLink = (path: string) => {
    onNavigate?.();
    navigate(path);
  };

  const handleGoHome = (event: MouseEvent<HTMLAnchorElement>) => {
    event.preventDefault();
    onNavigate?.();
    navigate('/');
  };

  const displayName = user?.name?.trim() || 'Usuario Pedestal';
  const displayEmail = user?.email?.trim() || 'usuario@pedestal.com';
  const avatarInitial = displayName.charAt(0).toUpperCase() || 'P';

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
          {items.map((item, index) => (
            <NavSectionItem
              key={item.key ?? `${item.label}-${item.link ?? index}`}
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
                <Avatar
                  src={user?.avatarSrc || undefined}
                  radius="xl"
                  size="md"
                  color="dark"
                >
                  {avatarInitial}
                </Avatar>
                <Box style={{ flex: 1, minWidth: 0 }}>
                  <Text size="sm" fw={500} truncate>
                    {displayName}
                  </Text>
                  <Text c="dimmed" size="xs" truncate>
                    {displayEmail}
                  </Text>
                </Box>
                <IconChevronRight size={15} stroke={1.6} />
              </Group>
            </UnstyledButton>
          </Menu.Target>

          <Menu.Dropdown>
            <Menu.Item
              leftSection={<IconUser size={15} />}
              onClick={() => {
                onNavigate?.();
                if (onProfileClick) {
                  onProfileClick();
                } else {
                  navigate('/profile');
                }
              }}
            >
              Mi perfil
            </Menu.Item>
            <Menu.Divider />
            <Menu.Item
              color="red"
              leftSection={<IconLogout size={15} />}
              onClick={() => {
                onNavigate?.();
                if (onLogoutClick) {
                  onLogoutClick();
                } else {
                  navigate('/login');
                }
              }}
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