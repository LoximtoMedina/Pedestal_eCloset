function Cart() {
  return (
    <main className="cart-page">
      <div className="continue-shopping">
        <button type="button">← Seguir comprando</button>
      </div>

      <section className="cart-hero">
        <h1>Mi carrito</h1>
        <p>Revisa tus productos antes de finalizar tu compra.</p>
      </section>

      <section className="cart-content">
        <div className="cart-products">
          <article className="cart-item">
            <div className="item-image" aria-label="Imagen de Camisa Oversize">
              IMG
            </div>

            <div className="item-info">
              <h3>Camisa Oversize</h3>
              <p>Talla M • Color Negro</p>
              <span>L 650</span>
            </div>

            <div className="item-quantity" aria-label="Cantidad de Camisa Oversize">
              <button type="button" aria-label="Reducir cantidad">−</button>
              <span>1</span>
              <button type="button" aria-label="Aumentar cantidad">+</button>
            </div>

            <div className="item-price">L 650</div>

            <button type="button" className="item-remove" aria-label="Eliminar Camisa Oversize">
              🗑
            </button>
          </article>

          <article className="cart-item">
            <div className="item-image" aria-label="Imagen de Pantalón Cargo">
              IMG
            </div>

            <div className="item-info">
              <h3>Pantalón Cargo</h3>
              <p>Talla L • Color Beige</p>
              <span>L 850</span>
            </div>

            <div className="item-quantity" aria-label="Cantidad de Pantalón Cargo">
              <button type="button" aria-label="Reducir cantidad">−</button>
              <span>1</span>
              <button type="button" aria-label="Aumentar cantidad">+</button>
            </div>

            <div className="item-price">L 850</div>

            <button type="button" className="item-remove" aria-label="Eliminar Pantalón Cargo">
              🗑
            </button>
          </article>

          <article className="cart-item">
            <div className="item-image" aria-label="Imagen de Gorra Urbana">
              IMG
            </div>

            <div className="item-info">
              <h3>Gorra Urbana</h3>
              <p>Talla Única • Color Blanco</p>
              <span>L 350</span>
            </div>

            <div className="item-quantity" aria-label="Cantidad de Gorra Urbana">
              <button type="button" aria-label="Reducir cantidad">−</button>
              <span>1</span>
              <button type="button" aria-label="Aumentar cantidad">+</button>
            </div>

            <div className="item-price">L 350</div>

            <button type="button" className="item-remove" aria-label="Eliminar Gorra Urbana">
              🗑
            </button>
          </article>
        </div>

        <aside className="cart-summary">
          <h2>Resumen del pedido</h2>

          <div className="summary-row">
            <span>Subtotal</span>
            <span>L 1,850</span>
          </div>

          <div className="summary-row">
            <span>Envío</span>
            <span>Gratis</span>
          </div>

          <div className="summary-row total">
            <span>Total</span>
            <span>L 1,850</span>
          </div>

          <button type="button" className="checkout-btn">
            Finalizar compra
          </button>

          <div className="summary-benefits">
            <div className="benefit">
              <span aria-hidden="true">🚚</span>
              <div>
                <h4>Envíos a toda Honduras</h4>
                <p>Recibe tu pedido en 2 a 5 días hábiles.</p>
              </div>
            </div>

            <div className="benefit">
              <span aria-hidden="true">📦</span>
              <div>
                <h4>Empaque de calidad</h4>
                <p>Tus productos llegan protegidos y en óptimas condiciones.</p>
              </div>
            </div>

            <div className="benefit">
              <span aria-hidden="true">🔒</span>
              <div>
                <h4>Compra segura</h4>
                <p>Tus datos están protegidos durante todo el proceso.</p>
              </div>
            </div>
          </div>
        </aside>
      </section>

      <section className="cart-extras">
        <div className="promo-code">
          <label htmlFor="promo-code">Código promocional</label>
          <input id="promo-code" name="promo-code" type="text" />
        </div>

        <div className="order-note">
          <label htmlFor="order-note">Nota para el pedido</label>
          <textarea id="order-note" name="order-note" rows={3} />
        </div>
      </section>
    </main>
  );
}

export default Cart;
