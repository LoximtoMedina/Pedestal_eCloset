import { useState } from 'react'
import './App.css'

// Importación de componentes
import Header from './componentes/header/header'

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      <Header />
    </>
  )
}

export default App
