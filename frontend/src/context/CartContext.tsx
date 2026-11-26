import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import type { ItemCarrito } from "../components/CartItems/CartItem";

/*
  Carrito compartido: catálogo, carrito y checkout leen y modifican LA MISMA lista.

  - El carrito se guarda en el navegador (localStorage), así que no se pierde al recargar.
  - Más adelante se puede guardar en la base de datos: las páginas seguirán usando
    useCart() igual, solo cambia lo de adentro de este archivo.
*/

/** Producto que se manda al carrito; la cantidad es opcional (por defecto 1). */
type NuevoItem = Omit<ItemCarrito, "cantidad"> & { cantidad?: number };

type CartContextValue = {
  items: ItemCarrito[];
  totalUnidades: number; // suma de las cantidades
  subtotal: number; // suma de precio × cantidad
  agregar: (item: NuevoItem) => void; // si ya existe, le suma a la cantidad
  cambiarCantidad: (id: number, delta: number) => void; // +1 o -1 (mínimo 1)
  quitar: (id: number) => void;
  vaciar: () => void;
};

const CLAVE_GUARDADO = "pedestal_carrito";

const CartContext = createContext<CartContextValue | null>(null);

function leerGuardado(): ItemCarrito[] {
  try {
    const crudo = localStorage.getItem(CLAVE_GUARDADO);
    const datos: unknown = crudo ? JSON.parse(crudo) : [];
    return Array.isArray(datos) ? (datos as ItemCarrito[]) : [];
  } catch {
    return [];
  }
}

export function CartProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<ItemCarrito[]>(leerGuardado);

  // cada vez que cambia el carrito, se guarda
  useEffect(() => {
    try {
      localStorage.setItem(CLAVE_GUARDADO, JSON.stringify(items));
    } catch {
      /* almacenamiento bloqueado o lleno: el carrito sigue funcionando sin guardarse */
    }
  }, [items]);

  const agregar = useCallback((nuevo: NuevoItem) => {
    const cantidad = nuevo.cantidad ?? 1;

    setItems((prev) =>
      prev.some((i) => i.id === nuevo.id)
        ? prev.map((i) =>
            i.id === nuevo.id ? { ...i, cantidad: i.cantidad + cantidad } : i,
          )
        : [...prev, { ...nuevo, cantidad }],
    );
  }, []);

  const cambiarCantidad = useCallback((id: number, delta: number) => {
    setItems((prev) =>
      prev.map((i) =>
        i.id === id ? { ...i, cantidad: Math.max(1, i.cantidad + delta) } : i,
      ),
    );
  }, []);

  const quitar = useCallback((id: number) => {
    setItems((prev) => prev.filter((i) => i.id !== id));
  }, []);

  const vaciar = useCallback(() => setItems([]), []);

  const valor = useMemo<CartContextValue>(
    () => ({
      items,
      totalUnidades: items.reduce((suma, i) => suma + i.cantidad, 0),
      subtotal: items.reduce((suma, i) => suma + i.precio * i.cantidad, 0),
      agregar,
      cambiarCantidad,
      quitar,
      vaciar,
    }),
    [items, agregar, cambiarCantidad, quitar, vaciar],
  );

  return <CartContext.Provider value={valor}>{children}</CartContext.Provider>;
}

// eslint-disable-next-line react-refresh/only-export-components
export function useCart() {
  const contexto = useContext(CartContext);

  if (!contexto) {
    throw new Error("useCart debe usarse dentro de <CartProvider>");
  }

  return contexto;
}
