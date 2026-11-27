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
  const { totalUnidades } = useCart();

  const items = useMemo<HeaderNavItem[]>(
    () => [
      {
        key: "cart",
        label: totalUnidades > 0 ? `Carrito (${totalUnidades})` : "Carrito",
        to: "/shop/cart",
      },
    ],
    [totalUnidades],
  );

  useEffect(() => {
    setNavItems(items);

    // al salir de la página, el header se queda sin estos enlaces
    return () => setNavItems([]);
  }, [items, setNavItems]);
}
