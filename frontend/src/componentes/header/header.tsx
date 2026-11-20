// Importación de dependencias necesarias para el componente Header
import { useState } from 'react'
import { Menu } from 'antd'

// Importación de estilos CSS para el componente Header
import './header.css'

// importación de la imagen del logo de la aplicación
import logo from '../../assets/PedestalLogo.svg'


function Header() {
  const [openMenu, setOpenMenu] = useState(0)

  return (
    <header>
        {/* Sección del logo de la aplicación (Logo + Texto)*/}
        <div className='logo'>
            <img src={logo} alt="Logo" />
            <h1>Pedestal</h1>
        </div>

        {/* Sección de navegación de la página (Esto será variable porque puede incluir más o menos cosas dependiendo de la página)*/}
        <nav>
            <Menu
                mode = 'horizontal'
                items = {
                    [{
                        label: 'Ofertas',
                        key: 'offers',
                    },
                    {
                        label: 'Sobre Nosotros',
                        key: 'aboutUs',
                    },
                    {
                        label: 'Contáctanos',
                        key: 'contactUs',
                    }]
                }
            >
            </Menu>
        </nav>
        
        {/* Sección de botones de sesión (Iniciar Sesión, Registrarse) */}
        <div className='sessionButtons'>
            <button>Iniciar Sesión</button>
            <button>Registrarse</button>
        </div>
    </header>
  )
}

export default Header