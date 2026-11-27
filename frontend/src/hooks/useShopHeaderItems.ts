import { useEffect, useMemo } from "react";
import { useOutletContext } from "react-router";
import type { HeaderNavItem } from "../components/header/header";
import { useCart } from "../context/CartContext";
import type { LayoutNavOutletContext } from "./useLayoutNavItems";

/**
 * Pone el enlace "Carrito" en el header, con el número de productos que hay en el carrito.
 * Se usa dentro de una página que esté debajo del PublicLayout (catálogo, detalle...).
 */
export function useShopHeaderItems() {
  const { setNavItems } = useOutletContext<LayoutNavOutletContext<HeaderNavItem>>();
  const { totalUnits } = useCart();

  // el texto del enlace cambia solo cuando cambia la cantidad de productos
  const items = useMemo<HeaderNavItem[]>(
    () => [
      {
        key: "cart",
        label: totalUnits > 0 ? `Carrito (${totalUnits})` : "Carrito",
        to: "/shop/cart",
      },
    ],
    [totalUnits],
  );

  // al entrar se ponen los enlaces y al salir se quitan, para no dejarlos en otras páginas
  useEffect(() => {
    setNavItems(items);

    return () => setNavItems([]);
  }, [items, setNavItems]);
}
