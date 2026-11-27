import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

/*
  Carrito compartido: catálogo, detalle, carrito y checkout leen y modifican LA MISMA lista.

  - Cada línea es un producto en una talla y un color. La misma playera en M y en L son
    dos líneas distintas; si agregas la misma combinación otra vez, sube la cantidad.
  - `id` identifica la línea (lo usan los componentes de abajo); `productId` es el id del
    producto en el catálogo.
  - El carrito se guarda en el navegador (localStorage), así que no se pierde al recargar.
  - Cuando exista la API, este archivo cambia por dentro y las páginas siguen usando
    useCart() igual.
*/

/** Una línea del carrito: un producto en UNA talla y UN color. */
export type CartLine = {
  id: number; // identificador de la línea del carrito
  productId: number; // identificador del producto en el catálogo
  name: string; // nombre que ve el cliente
  size: string; // talla elegida ("M", "L", "Única"...)
  color: string; // nombre del color elegido ("Negro", "Beige"...)
  price: number; // precio de UNA unidad, en lempiras
  quantity: number; // unidades en el carrito
  image?: string; // ruta de la foto; si falta se muestra "IMG"
};

/** Lo que se manda a `addItem`: todavía no tiene id de línea y la cantidad es opcional. */
export type NewCartLine = Omit<CartLine, "id" | "quantity"> & {
  quantity?: number;
};

type CartContextValue = {
  items: CartLine[];
  totalUnits: number; // suma de las cantidades
  subtotal: number; // suma de precio × cantidad
  addItem: (item: NewCartLine) => void; // si la talla y el color ya están, suma a la cantidad
  changeQuantity: (id: number, delta: number) => void; // id de la línea; +1 o -1 (mínimo 1)
  removeItem: (id: number) => void; // id de la línea
  clear: () => void;
};

const STORAGE_KEY = "pedestal_carrito";

const CartContext = createContext<CartContextValue | null>(null);

/* ---------- lectura del carrito guardado ---------- */

/**
 * Carritos guardados con nombres viejos (nombre, talla, precio...) se convierten
 * a la forma actual, para que nada se vea vacío después de este cambio.
 */
type LegacyLine = Partial<CartLine> & {
  productoId?: number;
  nombre?: string;
  talla?: string;
  precio?: number;
  cantidad?: number;
  imagen?: string;
};

const normalizeLine = (raw: LegacyLine): CartLine => ({
  id: raw.id ?? 0,
  productId: raw.productId ?? raw.productoId ?? raw.id ?? 0,
  name: raw.name ?? raw.nombre ?? "",
  size: raw.size ?? raw.talla ?? "Única",
  color: raw.color ?? "Estándar",
  price: raw.price ?? raw.precio ?? 0,
  quantity: raw.quantity ?? raw.cantidad ?? 1,
  image: raw.image ?? raw.imagen,
});

/** Lee el carrito del navegador. Si hay cualquier error, arranca vacío. */
function loadSavedCart(): CartLine[] {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    const data: unknown = stored ? JSON.parse(stored) : [];
    if (!Array.isArray(data)) return [];
    return (data as LegacyLine[]).map(normalizeLine);
  } catch {
    return [];
  }
}

/* ---------- provider ---------- */

export function CartProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<CartLine[]>(loadSavedCart);

  // cada vez que cambia el carrito, se guarda
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
    } catch {
      /* almacenamiento bloqueado o lleno: el carrito sigue funcionando sin guardarse */
    }
  }, [items]);

  // agrega una línea nueva, o le suma cantidad si ya existe la misma talla y color
  const addItem = useCallback((newItem: NewCartLine) => {
    const { quantity = 1, ...rest } = newItem;

    setItems((prev) => {
      const existing = prev.find(
        (line) =>
          line.productId === rest.productId &&
          line.size === rest.size &&
          line.color === rest.color,
      );

      if (existing) {
        return prev.map((line) =>
          line === existing
            ? { ...line, quantity: line.quantity + quantity }
            : line,
        );
      }

      const nextId = prev.reduce((max, line) => Math.max(max, line.id), 0) + 1;
      return [...prev, { ...rest, id: nextId, quantity }];
    });
  }, []);

  // suma o resta unidades a una línea (nunca baja de 1)
  const changeQuantity = useCallback((id: number, delta: number) => {
    setItems((prev) =>
      prev.map((line) =>
        line.id === id
          ? { ...line, quantity: Math.max(1, line.quantity + delta) }
          : line,
      ),
    );
  }, []);

  // quita una línea completa
  const removeItem = useCallback((id: number) => {
    setItems((prev) => prev.filter((line) => line.id !== id));
  }, []);

  // vacía el carrito
  const clear = useCallback(() => setItems([]), []);

  const value = useMemo<CartContextValue>(
    () => ({
      items,
      totalUnits: items.reduce((sum, line) => sum + line.quantity, 0),
      subtotal: items.reduce((sum, line) => sum + line.price * line.quantity, 0),
      addItem,
      changeQuantity,
      removeItem,
      clear,
    }),
    [items, addItem, changeQuantity, removeItem, clear],
  );

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

// eslint-disable-next-line react-refresh/only-export-components
export function useCart() {
  const context = useContext(CartContext);

  if (!context) {
    throw new Error("useCart debe usarse dentro de <CartProvider>");
  }

  return context;
}
