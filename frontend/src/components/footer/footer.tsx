import { ActionIcon, Group, Stack, Text } from '@mantine/core';
import { IconBrandFacebook, IconBrandGithub, IconBrandInstagram } from '@tabler/icons-react';
import { useViewportType } from '../../hooks/useViewportType';
import './footer.css';

interface FooterLinkItem {
  label: string;
  href: string;
}

interface FooterGroupItem {
  title: string;
  links: FooterLinkItem[];
}

const footerGroups: FooterGroupItem[] = [
  {
    title: 'Explorar',
    links: [
      { label: 'Ofertas', href: '#offers' },
      { label: 'Sobre Nosotros', href: '#about' },
      { label: 'Novedades', href: '#new' },
      { label: 'Colecciones', href: '#collections' },
    ],
  },
  {
    title: 'Contáctanos',
    links: [
      { label: 'Legal', href: '#legal' },
      { label: 'Contacto', href: '#contact' },
    ],
  },
];

function Footer() {
  const viewport = useViewportType();
  const isMobile = viewport === 'mobile';

  return (
    <footer className={`pedestalFooter pedestalFooter--${viewport}`}>
      <div className="pedestalFooterInner">
        {/* Columna izquierda: Marca + descripción + redes */}
        <div className="pedestalFooterBrand">
          <Text fw={700} size="lg" className="pedestalFooterTitleBrand">
            Ecloset
          </Text>
          <Text size="sm" className="pedestalFooterDescription">
            Tu espacio digital para organizar, descubrir y renovar tu clóset con estilo.
          </Text>

          <Group gap="xs" className="pedestalFooterSocial" justify={isMobile ? 'center' : 'flex-start'}>
            <ActionIcon
              component="a"
              href="#instagram"
              aria-label="Instagram"
              variant="subtle"
              color="gray"
              size="lg"
              className="pedestalFooterSocialBtn"
            >
              <IconBrandInstagram size={20} stroke={1.6} />
            </ActionIcon>

            <ActionIcon
              component="a"
              href="#github"
              aria-label="GitHub"
              variant="subtle"
              color="gray"
              size="lg"
              className="pedestalFooterSocialBtn"
            >
              <IconBrandGithub size={20} stroke={1.6} />
            </ActionIcon>

            <ActionIcon
              component="a"
              href="#facebook"
              aria-label="Facebook"
              variant="subtle"
              color="gray"
              size="lg"
              className="pedestalFooterSocialBtn"
            >
              <IconBrandFacebook size={20} stroke={1.6} />
            </ActionIcon>
          </Group>
        </div>

        {/* Columnas derechas: Grupos de enlaces */}
        <div className="pedestalFooterGroups">
          {footerGroups.map((group) => (
            <div key={group.title} className="pedestalFooterColumn">
              <Text fw={600} size="sm" className="pedestalFooterColumnTitle">
                {group.title}
              </Text>

              <Stack gap={6} className="pedestalFooterLinkList">
                {group.links.map((item) => (
                  <a key={item.label} href={item.href} className="pedestalFooterLink">
                    {item.label}
                  </a>
                ))}
              </Stack>
            </div>
          ))}
        </div>
      </div>
    </footer>
  );
}

export default Footer;