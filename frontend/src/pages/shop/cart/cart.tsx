import { useState, type ReactNode } from "react";
import CartItem, {
  type ItemCarrito,
} from "../../../components/CartItems/cartItem";
import {
  IconoCaja,
  IconoCamion,
  IconoCandado,
  IconoChevronAbajo,
  IconoChevronIzquierda,
  IconoEscudo,
  IconoFlechaDerecha,
  IconoNota,
  IconoRegalo,
} from "../../../components/icons/icons";
import { formatoPrecio } from "../../../assets/utils/formatoPrecio";
import "./cart.css";

/* ===================================
   DATOS (por ahora fijos; luego vendrán del carrito del cliente)
=================================== */

const ITEMS_INICIALES: ItemCarrito[] = [
  { id: 1, nombre: "Camisa Oversize", talla: "M", color: "Negro", precio: 650, cantidad: 1 },
  { id: 2, nombre: "Pantalón Cargo", talla: "L", color: "Beige", precio: 850, cantidad: 1 },
  { id: 3, nombre: "Gorra Urbana", talla: "Única", color: "Blanco", precio: 350, cantidad: 1 },
];

const BENEFICIOS = [
  {
    Icono: IconoCamion,
    titulo: "Envíos a toda Honduras",
    texto: "Recibe tu pedido en 2 a 5 días hábiles.",
  },
  {
    Icono: IconoCaja,
    titulo: "Empaque de calidad",
    texto: "Tus productos llegan protegidos y en óptimas condiciones.",
  },
  {
    Icono: IconoEscudo,
    titulo: "Compra segura",
    texto: "Tus datos están protegidos durante todo el proceso.",
  },
];

/* ===================================
   SECCIÓN DESPLEGABLE (código promocional / nota)
=================================== */

function SeccionExtra({
  icono,
  titulo,
  children,
}: {
  icono: ReactNode;
  titulo: string;
  children: ReactNode;
}) {
  const [abierta, setAbierta] = useState(false);

  return (
    <div className="extra">
      <button
        type="button"
        className="extra__head"
        aria-expanded={abierta}
        onClick={() => setAbierta(!abierta)}
      >
        {icono}
        <span>{titulo}</span>
        <IconoChevronAbajo size={18} className="chevron" />
      </button>

      {abierta && <div className="extra__body">{children}</div>}
    </div>
  );
}

/* ===================================
   PÁGINA
=================================== */

function Cart() {
  const [items, setItems] = useState<ItemCarrito[]>(ITEMS_INICIALES);

  const cambiarCantidad = (id: number, delta: number) =>
    setItems((prev) =>
      prev.map((i) =>
        i.id === id ? { ...i, cantidad: Math.max(1, i.cantidad + delta) } : i,
      ),
    );

  const quitar = (id: number) =>
    setItems((prev) => prev.filter((i) => i.id !== id));

  const totalUnidades = items.reduce((suma, i) => suma + i.cantidad, 0);
  const subtotal = items.reduce((suma, i) => suma + i.precio * i.cantidad, 0);
  const palabra = totalUnidades === 1 ? "producto" : "productos";

  return (
    <main className="cart-page">
      <div className="cart-container">
        {/* TODO: conectar con la ruta del catálogo, por ejemplo navigate("/shop/catalog") */}
        <button type="button" className="continue-shopping">
          <IconoChevronIzquierda size={18} />
          Seguir comprando
        </button>

        <section className="cart-content">
          <div className="cart-main">
            <header className="cart-hero">
              <div>
                <h1>Tu carrito</h1>
                <p>Revisa tus productos antes de continuar.</p>
              </div>

              <span className="cart-count">
                {totalUnidades} {palabra}
              </span>
            </header>

            {items.length > 0 ? (
              <div className="cart-products">
                {items.map((item) => (
                  <CartItem
                    key={item.id}
                    item={item}
                    onCambiarCantidad={cambiarCantidad}
                    onQuitar={quitar}
                  />
                ))}
              </div>
            ) : (
              <div className="cart-empty">
                <h3>Tu carrito está vacío</h3>
                <p>Agrega productos desde el catálogo para verlos aquí.</p>
              </div>
            )}

            <div className="cart-extras">
              <SeccionExtra
                icono={<IconoRegalo size={22} />}
                titulo="¿Tienes un código promocional?"
              >
                <input
                  id="promo-code"
                  name="promo-code"
                  type="text"
                  placeholder="Escribe tu código"
                  aria-label="Código promocional"
                />
                <button type="button">Aplicar</button>
              </SeccionExtra>

              <SeccionExtra
                icono={<IconoNota size={22} />}
                titulo="Agregar una nota a tu pedido (opcional)"
              >
                <textarea
                  id="order-note"
                  name="order-note"
                  rows={3}
                  placeholder="Escribe una nota para tu pedido"
                  aria-label="Nota para el pedido"
                />
              </SeccionExtra>
            </div>
          </div>

          <aside className="cart-summary">
            <h2>Resumen del pedido</h2>

            <div className="summary-row">
              <span>
                Subtotal ({totalUnidades} {palabra})
              </span>
              <span>{formatoPrecio(subtotal)}</span>
            </div>

            <div className="summary-row">
              <span>Envío</span>
              <span className="summary-row__muted">Se calcula en el siguiente paso</span>
            </div>

            <div className="summary-total">
              <span className="summary-total__label">Total</span>
              <span className="summary-total__amount">{formatoPrecio(subtotal)}</span>
            </div>
            <p className="summary-tax">Impuestos incluidos</p>

            <button
              type="button"
              className="checkout-btn"
              disabled={items.length === 0}
            >
              Finalizar compra
              <IconoFlechaDerecha size={20} />
            </button>

            <p className="secure-note">
              <IconoCandado size={15} />
              Pago seguro y encriptado
            </p>

            <div className="summary-benefits">
              {BENEFICIOS.map(({ Icono, titulo, texto }) => (
                <div className="benefit" key={titulo}>
                  <Icono size={26} />
                  <div>
                    <h4>{titulo}</h4>
                    <p>{texto}</p>
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