import './catalog.css';

function catalog() {

  return (
    <>
        <main>

    {/* HERO COMPLETO */}

    <section className="catalog-hero">

        <div className="hero-content">

            <span className="hero-subtitle">
                NUEVA COLECCIÓN
            </span>

            <h1>
                Estilo sin límites
            </h1>

            <p>
                Prendas que se adaptan a tu historia.
            </p>

            <button className="hero-btn">
                Explorar ahora →
            </button>

        </div>

        <div className="hero-image">
            IMAGEN BANNER
        </div>

        <div className="hero-side-text">
            MÁS QUE ROPA
        </div>

    </section>

    {/* CONTENEDOR CENTRAL */}

    <div className="catalog-container">

        <section className="catalog-breadcrumb">
            Inicio {'>'} Catálogo
        </section>

        <section className="catalog-content">

            {/* FILTROS */}

            <aside className="catalog-filters">

                <div className="filters-title">
                    <h3>Filtrar productos</h3>
                </div>

                <div className="filter-category">

                    <h4>Categorías</h4>

                    <label>
                        <input type="checkbox" />
                        Todo
                    </label>

                    <label>
                        <input type="checkbox" />
                        Playeras
                    </label>

                    <label>
                        <input type="checkbox" />
                        Sudaderas
                    </label>

                    <label>
                        <input type="checkbox" />
                        Pantalones
                    </label>

                    <label>
                        <input type="checkbox" />
                        Accesorios
                    </label>

                </div>

                <div className="filter-size">

                    <h4>Tallas</h4>

                    <div className="sizes">

                        <button>XS</button>
                        <button>S</button>
                        <button>M</button>
                        <button>L</button>
                        <button>XL</button>

                    </div>

                </div>

                <div className="filter-color">

                    <h4>Colores</h4>

                    <div className="colors">

                        <span className="color black"></span>
                        <span className="color white"></span>
                        <span className="color gray"></span>
                        <span className="color beige"></span>
                        <span className="color brown"></span>

                    </div>

                </div>

                <div className="filter-price">

                    <h4>Precio</h4>

                    <input
                        type="range"
                        min="0"
                        max="2000"
                    />

                </div>

                <button className="clear-filters">
                    Limpiar filtros
                </button>

            </aside>

            {/* PRODUCTOS */}

            <div className="catalog-products">

                <div className="catalog-header">

                    <div className="catalog-title">

                        <h2>Catálogo</h2>

                        <p>
                            Descubre nuestras prendas y encuentra tu próximo favorito.
                        </p>

                    </div>

                    <div className="catalog-controls">

                        <div className="catalog-sort">
                            Más populares ▼
                        </div>

                        <div className="catalog-count">
                            24 productos
                        </div>

                    </div>

                </div>

                <div className="products-grid">

                    {/* PRODUCTO 1 */}

                    <div className="product-card">

                        <div className="product-badge">
                            Nuevo
                        </div>

                        <div className="favorite-btn">
                            ♥
                        </div>

                        <div className="product-image">
                            IMG
                        </div>

                        <div className="product-info">

                            <h3>Playera Essential</h3>

                            <p>L 450.00</p>

                            <div className="product-colors">

                                <span className="color black"></span>
                                <span className="color gray"></span>
                                <span className="color beige"></span>

                            </div>

                        </div>

                        <div className="product-cart">
                            🛍
                        </div>

                    </div>

                    {/* PRODUCTO 2 */}

                    <div className="product-card">

                        <div className="favorite-btn">
                            ♥
                        </div>

                        <div className="product-image">
                            IMG
                        </div>

                        <div className="product-info">

                            <h3>Sudadera Minimal</h3>

                            <p>L 850.00</p>

                            <div className="product-colors">

                                <span className="color black"></span>
                                <span className="color gray"></span>
                                <span className="color beige"></span>

                            </div>

                        </div>

                        <div className="product-cart">
                            🛍
                        </div>

                    </div>

                    {/* PRODUCTO 3 */}

                    <div className="product-card">

                        <div className="product-badge">
                            Más vendido
                        </div>

                        <div className="favorite-btn">
                            ♥
                        </div>

                        <div className="product-image">
                            IMG
                        </div>

                        <div className="product-info">

                            <h3>Pantalón Cargo</h3>

                            <p>L 950.00</p>

                            <div className="product-colors">

                                <span className="color black"></span>
                                <span className="color gray"></span>
                                <span className="color beige"></span>

                            </div>

                        </div>

                        <div className="product-cart">
                            🛍
                        </div>

                    </div>

                    {/* PRODUCTO 4 */}

                    <div className="product-card">

                        <div className="favorite-btn">
                            ♥
                        </div>

                        <div className="product-image">
                            IMG
                        </div>

                        <div className="product-info">

                            <h3>Gorra Classic</h3>

                            <p>L 350.00</p>

                            <div className="product-colors">

                                <span className="color black"></span>
                                <span className="color gray"></span>
                                <span className="color beige"></span>

                            </div>

                        </div>

                        <div className="product-cart">
                            🛍
                        </div>

                    </div>

                </div>

            </div>

        </section>

    </div>

</main>
    </>
  );
}

export default catalog;