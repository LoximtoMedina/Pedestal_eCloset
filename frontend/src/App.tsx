import { useState } from 'react';
import '@mantine/core/styles.css';
import { MantineProvider } from '@mantine/core';
import './App.css';

// Importación de componentes
import header from './componentes/header/header';
import footer from './componentes/footer/footer';

function App() {
  const [count, setCount] = useState(0);

  return (
    <>
      <MantineProvider>
        <header />
      </MantineProvider>
      
      <div className="App">

      </div>

      <MantineProvider>
        <footer />
      </MantineProvider>
    </>
  );
}

export default App;