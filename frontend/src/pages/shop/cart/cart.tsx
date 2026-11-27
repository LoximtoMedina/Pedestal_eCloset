import { useState, type ReactNode } from "react";
import { useNavigate } from "react-router";
import {
  IconArrowRight,
  IconChevronDown,
  IconChevronLeft,
  IconGift,
  IconLock,
  IconMinus,
  IconNote,
  IconPackage,
  IconPlus,
  IconShieldCheck,
  IconTrash,
  IconTruckDelivery,
} from "@tabler/icons-react";
import { useCart, type CartLine } from "../../../context/CartContext";
import { formatPrice } from "../../../utils/formatoPrecio";
import "./cart.css";

/* ===================================
   DATOS
   Beneficios que se muestran debajo del total (texto fijo por ahora).
=================================== */

const BENEFITS = [
  {
    Icon: IconTruckDelivery,
    title: "Envíos a toda Honduras",
    text: "Recibe tu pedido en 2 a 5 días hábiles.",
  },
  {
    Icon: IconPackage,
    title: "Empaque de calidad",
    text: "Tus productos llegan protegidos y en óptimas condiciones.",
  },
  {
    Icon: IconShieldCheck,
    title: "Compra segura",
    text: "Tus datos están protegidos durante todo el proceso.",
  },
];

/* ===================================
   FILA DE PRODUCTO
   Una línea del carrito: foto, nombre, talla/color, cantidad y total.
=================================== */

function CartItemRow({
  item,
  onChangeQuantity,
  onRemove,
}: {
  item: CartLine;
  onChangeQuantity: (id: number, delta: number) => void;
  onRemove: (id: number) => void;
}) {
  const { id, name, size, color, price, quantity, image } = item;

  return (
    <article className="cart-item">
      {/* foto o recuadro "IMG" */}
      <div className="cart-item__img">
        {image ? <img src={image} alt={name} loading="lazy" /> : <span>IMG</span>}
      </div>

      {/* nombre y variante elegida */}
      <div className="cart-item__info">
        <h3>{name}</h3>
        <p>
          Talla {size} · {color}
        </p>
      </div>

      {/* botón de eliminar la línea */}
      <button
        type="button"
        className="cart-item__remove"
        aria-label={`Eliminar ${name}`}
        onClick={() => onRemove(id)}
      >
        <IconTrash size={18} stroke={1.8} />
      </button>

      {/* precio unitario */}
      <p className="cart-item__price">{formatPrice(price)}</p>

      {/* cantidad con menos / más (nunca baja de 1) */}
      <div className="cart-item__qty" role="group" aria-label={`Cantidad de ${name}`}>
        <button
          type="button"
          aria-label="Reducir cantidad"
          disabled={quantity <= 1}
          onClick={() => onChangeQuantity(id, -1)}
        >
          <IconMinus size={16} stroke={2} />
        </button>

        <span aria-live="polite">{quantity}</span>

        <button
          type="button"
          aria-label="Aumentar cantidad"
          onClick={() => onChangeQuantity(id, 1)}
        >
          <IconPlus size={16} stroke={2} />
        </button>
      </div>

      {/* precio × cantidad */}
      <p className="cart-item__total">{formatPrice(price * quantity)}</p>
    </article>
  );
}

/* ===================================
   SECCIÓN DESPLEGABLE
   Se usa para el código promocional y la nota del pedido.
=================================== */

function ExtraSection({
  icon,
  title,
  children,
}: {
  icon: ReactNode;
  title: string;
  children: ReactNode;
}) {
  const [open, setOpen] = useState(false);

  return (
    <div className="extra">
      <button
        type="button"
        className="extra__head"
        aria-expanded={open}
        onClick={() => setOpen(!open)}
      >
        {icon}
        <span>{title}</span>
        <IconChevronDown size={18} stroke={1.8} className="chevron" />
      </button>

      {open && <div className="extra__body">{children}</div>}
    </div>
  );
}

/* ===================================
   PÁGINA
=================================== */

function Cart() {
  const navigate = useNavigate();
  const { items, totalUnits, subtotal, changeQuantity, removeItem } = useCart();

  const unitLabel = totalUnits === 1 ? "producto" : "productos";

  return (
    <main className="cart-page">
      <div className="cart-container">
        {/* volver al catálogo */}
        <button
          type="button"
          className="continue-shopping"
          onClick={() => navigate("/shop/catalog")}
        >
          <IconChevronLeft size={18} stroke={1.8} />
          Seguir comprando
        </button>

        <section className="cart-content">
          {/* ---------- columna izquierda: productos y extras ---------- */}
          <div className="cart-main">
            <div className="cart-hero">
              <div>
                <h1>Tu carrito</h1>
                <p>Revisa tus productos antes de continuar.</p>
              </div>

              <span className="cart-count">
                {totalUnits} {unitLabel}
              </span>
            </div>

            {/* lista de líneas o mensaje de carrito vacío */}
            {items.length > 0 ? (
              <div className="cart-products">
                {items.map((item) => (
                  <CartItemRow
                    key={item.id}
                    item={item}
                    onChangeQuantity={changeQuantity}
                    onRemove={removeItem}
                  />
                ))}
              </div>
            ) : (
              <div className="cart-empty">
                <h3>Tu carrito está vacío</h3>
                <p>Agrega productos desde el catálogo para verlos aquí.</p>
              </div>
            )}

            {/* código promocional y nota del pedido */}
            <div className="cart-extras">
              <ExtraSection
                icon={<IconGift size={22} stroke={1.8} />}
                title="¿Tienes un código promocional?"
              >
                <input
                  id="promo-code"
                  name="promo-code"
                  type="text"
                  placeholder="Escribe tu código"
                  aria-label="Código promocional"
                />
                <button type="button">Aplicar</button>
              </ExtraSection>

              <ExtraSection
                icon={<IconNote size={22} stroke={1.8} />}
                title="Agregar una nota a tu pedido (opcional)"
              >
                <textarea
                  id="order-note"
                  name="order-note"
                  rows={3}
                  placeholder="Escribe una nota para tu pedido"
                  aria-label="Nota para el pedido"
                />
              </ExtraSection>
            </div>
          </div>

          {/* ---------- columna derecha: resumen y totales ---------- */}
          <aside className="cart-summary">
            <h2>Resumen del pedido</h2>

            <div className="summary-row">
              <span>
                Subtotal ({totalUnits} {unitLabel})
              </span>
              <span>{formatPrice(subtotal)}</span>
            </div>

            <div className="summary-row">
              <span>Envío</span>
              <span className="summary-row__muted">Se calcula en el siguiente paso</span>
            </div>

            <div className="summary-total">
              <span className="summary-total__label">Total</span>
              <span className="summary-total__amount">{formatPrice(subtotal)}</span>
            </div>
            <p className="summary-tax">Impuestos incluidos</p>

            <button
              type="button"
              className="checkout-btn"
              disabled={items.length === 0}
              onClick={() => navigate("/shop/cart/checkout")}
            >
              Finalizar compra
              <IconArrowRight size={20} stroke={1.8} />
            </button>

            <p className="secure-note">
              <IconLock size={15} stroke={1.8} />
              Pago seguro y encriptado
            </p>

            {/* beneficios de la tienda */}
            <div className="summary-benefits">
              {BENEFITS.map(({ Icon, title, text }) => (
                <div className="benefit" key={title}>
                  <Icon size={26} stroke={1.6} />
                  <div>
                    <h4>{title}</h4>
                    <p>{text}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="summary-brand">
              MÁS QUE ROPA
              <strong>PEDESTAL</strong>
            </div>
          </aside>
        </section>
      </div>
    </main>
  );
}

export default Cart;
