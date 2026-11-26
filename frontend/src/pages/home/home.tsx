// Importacion de componentes
import { useState } from 'react';
import Carousel from '../../components/carousel/carousel';
import {
  Button,
  Container,
  Group,
  SimpleGrid,
  Text,
  Textarea,
  TextInput,
  Title,
} from '@mantine/core';
import { useForm } from '@mantine/form';
import { IconCircleFilled, IconDiamondFilled, IconTriangleFilled } from '@tabler/icons-react';
import { useViewportType } from '../../hooks/useViewportType';
import { useMemo } from 'react';
import { useLayoutNavItems } from '../../hooks/useLayoutNavItems';
import type { HeaderNavItem } from '../../components/header/header';

/*Importacion del css a la pagina home*/
import './home.css';

interface ContactFormValues {
  name: string;
  email: string;
  subject: string;
  message: string;
}

function Home() {
  const viewport = useViewportType();
  const [sentMessage, setSentMessage] = useState(false);

  const navItems = useMemo<HeaderNavItem[]>(
    () => [
      { key: 'offers', label: 'Ofertas', href: '#offers' },
      { key: 'about', label: 'Sobre Nosotros', href: '#about' },
      { key: 'contact', label: 'Contáctanos', href: '#contact' },
      { key: 'shop', label: 'Tienda', to: '/shop/catalog' },
    ],
    []
  );
  useLayoutNavItems<HeaderNavItem>(navItems);

  const contactForm = useForm<ContactFormValues>({
    initialValues: {
      name: '',
      email: '',
      subject: '',
      message: '',
    },
    validate: {
      name: (value) => (value.trim().length < 2 ? 'Ingresa tu nombre' : null),
      email: (value) => (!/^\S+@\S+$/.test(value) ? 'Ingresa un correo válido' : null),
      subject: (value) => (value.trim().length === 0 ? 'Escribe un asunto' : null),
    },
  });

  const handleContactSubmit = (values: ContactFormValues) => {
    setSentMessage(true);
    contactForm.reset();
    void values;
  };

  return (
    <main className={`homePage homePage--${viewport}`}>
      {/* Hero Section */}
      <section className={`pedestalHeroWrapper pedestalHeroWrapper--${viewport}`}>
        <Container className="pedestalHeroInner">
          <h1 className="pedestalHeroTitle">Eleva tu estilo</h1>

          <Text className="pedestalHeroDescription">
            Descubre prendas diseñadas para destacar tu identidad con elegancia y sofisticación.
          </Text>

          <Group justify="center" gap="md" className="pedestalHeroControls">
            <Button
              component="a"
              href="#collections"
              size="lg"
              radius="md"
              className="pedestalHeroPrimaryBtn"
            >
              Explorar colección
            </Button>

            <Button
              component="a"
              href="#offers"
              size="lg"
              radius="md"
              variant="default"
              className="pedestalHeroSecondaryBtn"
            >
              Ver ofertas
            </Button>
          </Group>
        </Container>
      </section>

      {/* Sección Carrusel */}
      <section id="offers" className="pedestalCarouselSection">
        <div className="pedestalCarouselHeader">
          Nuestras mejores ofertas disponibles para ti
        </div>

        <Carousel />

        <blockquote className="pedestalCarouselQuoteBox">
          <p className="pedestalCarouselQuoteText">
            “Lo que vistes es cómo te presentas al mundo, especialmente hoy, cuando los contactos
            humanos son tan rápidos. La moda es un lenguaje instantáneo”
          </p>
          <footer className="pedestalCarouselQuoteAuthor">- Miuccia Prada</footer>
        </blockquote>
      </section>

      {/* Sección de Acerca de nosotros */}
      <section id="about" className="pedestalAboutSection">
        <div className="pedestalAboutLeft">
          <Title order={2} className="pedestalAboutTitle">
            Acerca de nosotros
          </Title>
          <Text className="pedestalAboutDescription">
            PEDESTAL es una empresa dedicada a la comercializacion de prendas de vestir y
            accesorios mediante una plataforma digital integrada que une ERP, eCommerce y eCloset.
          </Text>
        </div>

        <div className="pedestalAboutRight">
          <div className="pedestalAboutCard">
            <div className="pedestalAboutCardHeader">
              <IconCircleFilled size={14} className="pedestalAboutIcon" />
              <Title order={3} className="pedestalAboutCardTitle">
                Misión
              </Title>
            </div>
            <Text className="pedestalAboutCardText">
              Ofrecer una experiencia moderna y elegante en la adquisicion y gestion de prendas de
              vestir, integrando tecnologia, diseno y calidad para ayudar a los clientes a
              expresar su identidad.
            </Text>
          </div>

          <div className="pedestalAboutCard">
            <div className="pedestalAboutCardHeader">
              <IconDiamondFilled size={14} className="pedestalAboutIcon" />
              <Title order={3} className="pedestalAboutCardTitle">
                Visión
              </Title>
            </div>
            <Text className="pedestalAboutCardText">
              Convertirnos en la plataforma lider en gestion de moda digital y comercio
              electronico en Centroamerica.
            </Text>
          </div>

          <div className="pedestalAboutCard">
            <div className="pedestalAboutCardHeader">
              <IconTriangleFilled size={14} className="pedestalAboutIcon" />
              <Title order={3} className="pedestalAboutCardTitle">
                Valores
              </Title>
            </div>
            <Text className="pedestalAboutCardText">
              Elegancia, Innovacion, Calidad, Confianza, Responsabilidad y Exclusividad.
            </Text>
          </div>
        </div>
      </section>

      {/* Sección Contacto */}
      <section id="contact" className="pedestalContactSection">
        <Container size={640} className="pedestalContactInner">
          <form onSubmit={contactForm.onSubmit(handleContactSubmit)} className="pedestalContactForm">
            <Title order={2} className="pedestalContactTitle">
              Contáctanos
            </Title>

            <Text className="pedestalContactSubtitle">
              ¿Tienes alguna duda sobre tus pedidos o prendas? Escríbenos y te responderemos pronto.
            </Text>

            <SimpleGrid cols={{ base: 1, sm: 2 }} spacing="md" mt="xl">
              <TextInput
                label="Nombre"
                placeholder="Tu nombre"
                name="name"
                variant="filled"
                classNames={{
                  label: 'pedestalContactLabel',
                  input: 'pedestalContactInput',
                }}
                {...contactForm.getInputProps('name')}
              />

              <TextInput
                label="Correo electrónico"
                placeholder="tu@correo.com"
                name="email"
                variant="filled"
                classNames={{
                  label: 'pedestalContactLabel',
                  input: 'pedestalContactInput',
                }}
                {...contactForm.getInputProps('email')}
              />
            </SimpleGrid>

            <TextInput
              label="Asunto"
              placeholder="Asunto"
              mt="md"
              name="subject"
              variant="filled"
              classNames={{
                label: 'pedestalContactLabel',
                input: 'pedestalContactInput',
              }}
              {...contactForm.getInputProps('subject')}
            />

            <Textarea
              label="Mensaje"
              placeholder="Escribe tu mensaje"
              mt="md"
              minRows={5}
              maxRows={10}
              autosize
              name="message"
              variant="filled"
              classNames={{
                label: 'pedestalContactLabel',
                input: 'pedestalContactInput',
              }}
              {...contactForm.getInputProps('message')}
            />

            {sentMessage && (
              <Text size="sm" className="pedestalContactSuccess">
                ¡Mensaje enviado! Gracias por comunicarte con nosotros.
              </Text>
            )}

            <Group justify="center" mt="xl">
              <Button type="submit" size="md" radius="md" className="pedestalContactSubmitBtn">
                Enviar mensaje
              </Button>
            </Group>
          </form>
        </Container>
      </section>
    </main>
  );
}

export default Home;