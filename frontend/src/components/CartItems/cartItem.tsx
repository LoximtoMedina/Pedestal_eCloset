import { IconoMas, IconoMenos, IconoPapelera } from "../icons/icons";
import { formatoPrecio } from "../../assets/utils/formatoPrecio";
import "./cartItem.css";

/*
  Dónde va cada dato en la fila del carrito:

  ┌─────────┬──────────────────────────────────────┐
  │         │ nombre                           🗑  │  ← nombre + botón quitar
  │ imagen  │ Talla · color                        │  ← talla y color
  │         │ L precio     [ − 1 + ]    L subtotal │  ← precio unitario, cantidad, precio × cantidad
  └─────────┴──────────────────────────────────────┘
*/

/** Un producto dentro del carrito. Cada campo saldrá de la base de datos. */
export type ItemCarrito = {
  id: number; // identificador del producto (o de la línea del carrito)
  nombre: string; // nombre que ve el cliente
  talla: string; // talla elegida ("M", "L", "Única"...)
  color: string; // nombre del color elegido ("Negro", "Beige"...)
  precio: number; // precio de UNA unidad, en lempiras
  cantidad: number; // unidades en el carrito
  imagen?: string; // ruta de la foto; si falta se muestra "IMG"
};

type Props = {
  item: ItemCarrito;
  onCambiarCantidad: (id: number, delta: number) => void; // +1 o -1
  onQuitar: (id: number) => void;
};

function CartItem({ item, onCambiarCantidad, onQuitar }: Props) {
  const { id, nombre, talla, color, precio, cantidad, imagen } = item;

  return (
    <article className="cart-item">
      <div className="cart-item__img">
        {imagen ? <img src={imagen} alt={nombre} loading="lazy" /> : <span>IMG</span>}
      </div>

      <div className="cart-item__info">
        <h3>{nombre}</h3>
        <p>
          Talla {talla} · {color}
        </p>
      </div>

      <button
        type="button"
        className="cart-item__remove"
        aria-label={`Eliminar ${nombre}`}
        onClick={() => onQuitar(id)}
      >
        <IconoPapelera />
      </button>

      <p className="cart-item__price">{formatoPrecio(precio)}</p>

      <div className="cart-item__qty" role="group" aria-label={`Cantidad de ${nombre}`}>
        <button
          type="button"
          aria-label="Reducir cantidad"
          disabled={cantidad <= 1}
          onClick={() => onCambiarCantidad(id, -1)}
        >
          <IconoMenos size={16} />
        </button>

        <span aria-live="polite">{cantidad}</span>

        <button
          type="button"
          aria-label="Aumentar cantidad"
          onClick={() => onCambiarCantidad(id, 1)}
        >
          <IconoMas size={16} />
        </button>
      </div>

      <p className="cart-item__total">{formatoPrecio(precio * cantidad)}</p>
    </article>
  );
}

export default CartItem;