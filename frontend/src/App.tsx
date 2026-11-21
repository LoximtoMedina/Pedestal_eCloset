import { useState } from 'react';
import '@mantine/core/styles.css';
import { MantineProvider } from '@mantine/core';
import './App.css';

// Importación de componentes
import Header from './componentes/header/header';

function App() {
  const [count, setCount] = useState(0);

  return (
    <MantineProvider>
      <Header />
    </MantineProvider>
  );
}

export default App;