import { useDisclosure } from '@mantine/hooks';
import { useViewportType } from '../../hooks/useViewportType';
import './header.css';
import logo from '../../assets/PedestalLogo.svg';


function footer() {
  const viewport = useViewportType();

  const isMobile = viewport === 'mobile';

  return (
    <footer className={`footer footer--${viewport}`}>
    </footer>
  );
}

export default footer;