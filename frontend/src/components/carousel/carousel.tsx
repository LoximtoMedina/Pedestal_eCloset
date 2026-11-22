import { Carousel } from '@mantine/carousel';
import { Button, Paper, Text, Title } from '@mantine/core';
import { useViewportType } from '../../hooks/useViewportType';
import './carousel.css';

interface CarouselCardItem {
  id: string;
  image: string;
  title: string;
  category: string;
  ctaLabel: string;
  href: string;
}

const eclosetSlides: CarouselCardItem[] = [
  {
    id: 'ofertas-temporada',
    image:
      'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=800&q=80',
    title: 'Prendas esenciales para renovar tu clóset',
    category: 'Ofertas',
    ctaLabel: 'Ver ofertas',
    href: '#offers',
  },
  {
    id: 'colecciones-destacadas',
    image:
      'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=800&q=80',
    title: 'Combinaciones versátiles para el día a día',
    category: 'Colecciones',
    ctaLabel: 'Explorar colección',
    href: '#collections',
  },
  {
    id: 'novedades-semana',
    image:
      'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?auto=format&fit=crop&w=800&q=80',
    title: 'Lo más reciente que llegó a Ecloset',
    category: 'Novedades',
    ctaLabel: 'Ver novedades',
    href: '#new',
  },
  {
    id: 'estilo-personal',
    image:
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=800&q=80',
    title: 'Arma looks prácticos sin complicarte',
    category: 'Ecloset',
    ctaLabel: 'Conocer más',
    href: '#about',
  },
];

interface SlideCardProps {
  item: CarouselCardItem;
}

function SlideCard({ item }: SlideCardProps) {
  return (
    <Paper
      shadow="md"
      p="xl"
      radius="md"
      style={{ backgroundImage: `url(${item.image})` }}
      className="pedestalCarouselCard"
    >
      <div className="pedestalCarouselCardOverlay" />

      <div className="pedestalCarouselCardContent">
        <Text className="pedestalCarouselCategory" size="xs">
          {item.category}
        </Text>
        <Title order={3} className="pedestalCarouselTitle">
          {item.title}
        </Title>
      </div>

      <Button
        component="a"
        href={item.href}
        variant="white"
        color="dark"
        className="pedestalCarouselBtn"
      >
        {item.ctaLabel}
      </Button>
    </Paper>
  );
}

function carousel() {
  const viewport = useViewportType();
  const isMobile = viewport === 'mobile';

  return (
    <section className={`pedestalCarouselSection pedestalCarouselSection--${viewport}`}>
      <Carousel
        slideSize={{ base: '100%', sm: '50%' }}
        slideGap="md"
        emblaOptions={{
          align: 'start',
          slidesToScroll: isMobile ? 1 : 2,
          loop: true,
        }}
        nextControlProps={{ 'aria-label': 'Siguiente slide' }}
        previousControlProps={{ 'aria-label': 'Slide anterior' }}
        classNames={{
          root: 'pedestalCarouselRoot',
          container: 'pedestalCarouselContainer',
          slide: 'pedestalCarouselSlide',
          control: 'pedestalCarouselControl',
        }}
      >
        {eclosetSlides.map((item) => (
          <Carousel.Slide key={item.id}>
            <SlideCard item={item} />
          </Carousel.Slide>
        ))}
      </Carousel>
    </section>
  );
}

export default carousel;