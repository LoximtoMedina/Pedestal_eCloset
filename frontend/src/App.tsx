import '@mantine/core/styles.css';
import { MantineProvider } from '@mantine/core';
import './App.css';

// Importación de componentes
import Header from './components/header/header';
import Footer from './components/footer/footer';

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