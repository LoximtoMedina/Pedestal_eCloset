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
  Carrito compartido: catálogo, detalle, carrito y checkout leen y modifican LA MISMA lista.

  - Cada línea es un producto en una talla y un color. La misma playera en M y en L son
    dos líneas distintas; si agregas la misma combinación otra vez, sube la cantidad.
  - `id` identifica la línea (lo usan CartItem y las funciones de abajo);
    `productoId` es el id del producto en el catálogo.
  - El carrito se guarda en el navegador (localStorage), así que no se pierde al recargar.
  - Más adelante se puede guardar en la base de datos: las páginas seguirán usando
    useCart() igual, solo cambia lo de adentro de este archivo.
*/

export type LineaCarrito = ItemCarrito & { productoId: number };

/** Lo que se manda a `agregar`: no lleva `id` de línea (se genera aquí) y la cantidad es opcional. */
type NuevoItem = Omit<ItemCarrito, "id" | "cantidad"> & {
  productoId: number;
  cantidad?: number;
};

type CartContextValue = {
  items: LineaCarrito[];
  totalUnidades: number; // suma de las cantidades
  subtotal: number; // suma de precio × cantidad
  agregar: (item: NuevoItem) => void; // si la talla y el color ya están, suma a la cantidad
  cambiarCantidad: (id: number, delta: number) => void; // id de la línea; +1 o -1 (mínimo 1)
  quitar: (id: number) => void; // id de la línea
  vaciar: () => void;
};

const CLAVE_GUARDADO = "pedestal_carrito";

const CartContext = createContext<CartContextValue | null>(null);

function leerGuardado(): LineaCarrito[] {
  try {
    const crudo = localStorage.getItem(CLAVE_GUARDADO);
    const datos: unknown = crudo ? JSON.parse(crudo) : [];
    if (!Array.isArray(datos)) return [];

    // los carritos guardados antes de este cambio no traen productoId: se usa el id
    return (datos as ItemCarrito[]).map((i) => ({
      ...i,
      productoId: (i as Partial<LineaCarrito>).productoId ?? i.id,
    }));
  } catch {
    return [];
  }
}

export function CartProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<LineaCarrito[]>(leerGuardado);

  // cada vez que cambia el carrito, se guarda
  useEffect(() => {
    try {
      localStorage.setItem(CLAVE_GUARDADO, JSON.stringify(items));
    } catch {
      /* almacenamiento bloqueado o lleno: el carrito sigue funcionando sin guardarse */
    }
  }, [items]);

  const agregar = useCallback((nuevo: NuevoItem) => {
    const { productoId, cantidad = 1, ...resto } = nuevo;

    setItems((prev) => {
      const existente = prev.find(
        (i) =>
          i.productoId === productoId &&
          i.talla === resto.talla &&
          i.color === resto.color,
      );

      if (existente) {
        return prev.map((i) =>
          i === existente ? { ...i, cantidad: i.cantidad + cantidad } : i,
        );
      }

      const siguienteId = prev.reduce((mayor, i) => Math.max(mayor, i.id), 0) + 1;
      return [...prev, { ...resto, id: siguienteId, productoId, cantidad }];
    });
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
