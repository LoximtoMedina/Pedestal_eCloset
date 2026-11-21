import { useState } from 'react';
import '@mantine/core/styles.css';
import { MantineProvider } from '@mantine/core';
import './App.css';

// Importación de componentes
import Header from './componentes/header/header';
import Footer from './componentes/footer/footer';

function App() {
  return (
    <MantineProvider>
      <Header />
    
      <div className="App"> </div>

      <Footer />
    </MantineProvider>
  );
}

export default App;