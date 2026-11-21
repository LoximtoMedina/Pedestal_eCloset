import { ActionIcon, Group, Stack, Text } from '@mantine/core';
import { IconBrandInstagram, IconBrandLinkedin, IconBrandX } from '@tabler/icons-react';
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
    title: 'Features',
    links: [
      { label: 'Core features', href: '#core-features' },
      { label: 'Pro experience', href: '#pro-experience' },
      { label: 'Integrations', href: '#integrations' },
    ],
  },
  {
    title: 'Learn more',
    links: [
      { label: 'Blog', href: '#blog' },
      { label: 'Case studies', href: '#case-studies' },
      { label: 'Customer stories', href: '#customer-stories' },
      { label: 'Best practices', href: '#best-practices' },
    ],
  },
  {
    title: 'Support',
    links: [
      { label: 'Contact', href: '#contact' },
      { label: 'Support', href: '#support' },
      { label: 'Legal', href: '#legal' },
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
            Namedly
          </Text>
          <Text size="sm" className="pedestalFooterDescription">
            Descriptive line about what your company does.
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
              href="#linkedin"
              aria-label="LinkedIn"
              variant="subtle"
              color="gray"
              size="lg"
              className="pedestalFooterSocialBtn"
            >
              <IconBrandLinkedin size={20} stroke={1.6} />
            </ActionIcon>

            <ActionIcon
              component="a"
              href="#x"
              aria-label="X"
              variant="subtle"
              color="gray"
              size="lg"
              className="pedestalFooterSocialBtn"
            >
              <IconBrandX size={20} stroke={1.6} />
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