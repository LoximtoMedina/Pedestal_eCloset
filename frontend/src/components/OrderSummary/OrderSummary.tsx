import { Link } from "react-router";
import type { ItemCarrito } from '../CartItems/cartItem';
import {
  IconoBolsa,
  IconoCaja,
  IconoCamion,
  IconoEscudo,
  IconoFlechaIzquierda,
} from "../icons/icons";
import { formatoPrecio } from "../../utils/formatoPrecio";
import "./OrderSummary.css";

/*
  ┌──────────────────────────────────────┐
  │ [bolsa] Resumen del pedido  Editar   │
  │ [foto] nombre                    x1  │  ← items: un renglón por producto
  │        Talla · color                 │
  │        L precio                      │
  │ Subtotal                    L ...    │  ← suma de precio × cantidad
  │ Envío                      Gratis    │  ← costoEnvio
  │ ──────────────────────────────────── │
  │ Total                       L ...    │  ← subtotal + costoEnvio
  │ [ beneficios ]                       │
  │ ← Volver al carrito                  │
  └──────────────────────────────────────┘
*/

const RUTA_CARRITO = "/shop/cart";

const BENEFICIOS = [
  {
    Icono: IconoCamion,
    titulo: "Envíos a toda Honduras",
    texto: "Recibe tu pedido en 2 a 5 días hábiles.",
  },
  {
    Icono: IconoCaja,
    titulo: "Empaque de calidad",
    texto: "Tus productos llegan protegidos.",
  },
  {
    Icono: IconoEscudo,
    titulo: "Compra segura",
    texto: "Tus datos están protegidos.",
  },
];

type Props = {
  items: ItemCarrito[]; // productos del carrito
  costoEnvio: number; // 0 = envío gratis
};

function OrderSummary({ items, costoEnvio }: Props) {
  const subtotal = items.reduce((suma, i) => suma + i.precio * i.cantidad, 0);
  const total = subtotal + costoEnvio;

  return (
    <aside className="order-summary" aria-label="Resumen del pedido">
      <header className="order-summary__head">
        <IconoBolsa size={26} />
        <h2>Resumen del pedido</h2>
        <Link to={RUTA_CARRITO} className="order-summary__link">
          Editar carrito
        </Link>
      </header>

      <ul className="order-summary__items">
        {items.map((item) => (
          <li key={item.id} className="order-summary__item">
            <div className="order-summary__thumb">
              {item.imagen && <img src={item.imagen} alt={item.nombre} loading="lazy" />}
            </div>

            <div>
              <p className="order-summary__name">{item.nombre}</p>
              <p className="order-summary__meta">
                Talla {item.talla} · {item.color}
              </p>
              <p className="order-summary__price">{formatoPrecio(item.precio)}</p>
            </div>

            <span className="order-summary__qty">x{item.cantidad}</span>
          </li>
        ))}
      </ul>

      <div className="order-summary__row">
        <span>Subtotal</span>
        <span>{formatoPrecio(subtotal)}</span>
      </div>

      <div className="order-summary__row">
        <span>Envío</span>
        <span>{costoEnvio === 0 ? "Gratis" : formatoPrecio(costoEnvio)}</span>
      </div>

      <div className="order-summary__total">
        <span>Total</span>
        <span>{formatoPrecio(total)}</span>
      </div>

      <div className="order-summary__benefits">
        {BENEFICIOS.map(({ Icono, titulo, texto }) => (
          <div className="order-summary__benefit" key={titulo}>
            <Icono size={28} />
            <div>
              <h3>{titulo}</h3>
              <p>{texto}</p>
            </div>
          </div>
        ))}
      </div>

      <Link to={RUTA_CARRITO} className="order-summary__back">
        <IconoFlechaIzquierda size={18} />
        Volver al carrito
      </Link>
    </aside>
  );
}

export default OrderSummary;
