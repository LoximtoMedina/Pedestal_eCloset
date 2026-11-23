import Header from "../../../components/header/header";
import Footer from "../../../components/footer/footer";

function Home() {
  return (
    <>
      <Header />
<main className="cart-page">

    <div className="continue-shopping">
        <button>
            ← Seguir comprando
        </button>
    </div>

    <section className="cart-hero">
        <h1>Mi carrito</h1>
        <p>Revisa tus productos antes de finalizar tu compra.</p>
    </section>

    <section className="cart-content">

        <div className="cart-products">

            <div className="cart-item">

                <div className="item-image">
                    IMG
                </div>

                <div className="item-info">
                    <h3>Camisa Oversize</h3>
                    <p>Talla M • Color Negro</p>
                    <span>L 650</span>
                </div>

                <div className="item-quantity">
                    <button>-</button>
                    <span>1</span>
                    <button>+</button>
                </div>

                <div className="item-price">
                    L 650
                </div>

                <div className="item-remove">
                    🗑
                </div>

            </div>

            <div className="cart-item">

                <div className="item-image">
                    IMG
                </div>

                <div className="item-info">
                    <h3>Pantalón Cargo</h3>
                    <p>Talla L • Color Beige</p>
                    <span>L 850</span>
                </div>

                <div className="item-quantity">
                    <button>-</button>
                    <span>1</span>
                    <button>+</button>
                </div>

                <div className="item-price">
                    L 850
                </div>

                <div className="item-remove">
                    🗑
                </div>

            </div>

            <div className="cart-item">

                <div className="item-image">
                    IMG
                </div>

                <div className="item-info">
                    <h3>Gorra Urbana</h3>
                    <p>Talla Única • Color Blanco</p>
                    <span>L 350</span>
                </div>

                <div className="item-quantity">
                    <button>-</button>
                    <span>1</span>
                    <button>+</button>
                </div>

                <div className="item-price">
                    L 350
                </div>

                <div className="item-remove">
                    🗑
                </div>

            </div>

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

            <button className="checkout-btn">
                Finalizar compra
            </button>

            <div className="summary-benefits">

                <div className="benefit">
                    <span>🚚</span>
                    <div>
                        <h4>Envíos a toda Honduras</h4>
                        <p>Recibe tu pedido en 2 a 5 días hábiles.</p>
                    </div>
                </div>

                <div className="benefit">
                    <span>📦</span>
                    <div>
                        <h4>Empaque de calidad</h4>
                        <p>Tus productos llegan protegidos y en óptimas condiciones.</p>
                    </div>
                </div>

                <div className="benefit">
                    <span>🔒</span>
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
            Código promocional
        </div>

        <div className="order-note">
            Nota para el pedido
        </div>

    </section>

</main>
      <Footer />
    </>
  );
}

export default Home;
