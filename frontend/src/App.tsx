/* ==========================================================================
   1. ESTILOS BASE Y DE LIBRERÍAS (MANTINE + ESTILOS GLOBALES DE LA APP)
   ========================================================================== */
import '@mantine/core/styles.css';
import '@mantine/carousel/styles.css';
import './App.css';


/* ==========================================================================
   2. PROVEEDORES DE APLICACIÓN Y NAVEGACIÓN
   ========================================================================== */
import { MantineProvider } from '@mantine/core';
import { BrowserRouter } from 'react-router';
import { AuthProvider } from './context/authContext';
import AppRoutes from './routes/appRoutes';


/* ==========================================================================
   3. COMPONENTE RAÍZ DE LA APLICACIÓN
   --------------------------------------------------------------------------
   Envuelve la app con:
   - AuthProvider: maneja el estado de sesión y usuario de forma global.
   - MantineProvider: provee el tema y componentes de interfaz de Mantine.
   - BrowserRouter: habilita el enrutamiento basado en la URL del navegador.
   ========================================================================== */
function App() {
  return (
    <AuthProvider>
      <MantineProvider>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </MantineProvider>
    </AuthProvider>
  );
}

export default App;