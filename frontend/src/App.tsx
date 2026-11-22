import '@mantine/core/styles.css';
import { MantineProvider } from '@mantine/core';
import { BrowserRouter } from 'react-router';
import './App.css';
import AppRoutes from './routes/appRoutes';

function App() {
  // Más adelante esto vendrá de AuthContext
  const isAuthenticated = false;

  return (
    <MantineProvider>
      <BrowserRouter>
        <AppRoutes isAuthenticated={isAuthenticated} />
      </BrowserRouter>
    </MantineProvider>
  );
}

export default App;