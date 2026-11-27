import { useMemo, useState, type ReactNode } from "react";
import { IconArrowRight, IconChevronRight, IconChevronUp } from "@tabler/icons-react";
import ProductCard, { type Product } from "../../../components/ProductCard/ProductCard";
import { useCart } from "../../../context/CartContext";
import { PRODUCTS, toCartItem } from "../../../data/productos";
import { useShopHeaderItems } from "../../../hooks/useShopHeaderItems";
import "./catalog.css";

/* ===================================
   DATOS DE LOS FILTROS
   (por ahora fijos; luego se arman desde los productos de la base)
=================================== */

const MAX_PRICE = 2000;
const PRICE_STEP = 50;

const CATEGORIES = [
  "Todo",
  "Playeras",
  "Sudaderas",
  "Pantalones",
  "Accesorios",
  "Gorras",
  "Chaquetas",
];

const SIZES = ["XS", "S", "M", "L", "XL"];

const FILTER_COLORS = [
  { name: "Negro", hex: "#111111" },
  { name: "Blanco", hex: "#ffffff" },
  { name: "Gris", hex: "#858585" },
  { name: "Beige", hex: "#dccfbd" },
  { name: "Verde oliva", hex: "#4d5136" },
  { name: "Café", hex: "#6b4a36" },
];

type SortOrder = "popular" | "newest" | "price-asc" | "price-desc";

/** Agrega el valor a la lista si no está, o lo quita si ya está. */
const toggleValue = (list: string[], value: string) =>
  list.includes(value) ? list.filter((item) => item !== value) : [...list, value];

/* ===================================
   SECCIÓN COLAPSABLE DE FILTROS
=================================== */

function FilterSection({ title, children }: { title: string; children: ReactNode }) {
  const [open, setOpen] = useState(true);

  return (
    <div className="filter-section">
      <button
        type="button"
        className="filter-section__head"
        aria-expanded={open}
        onClick={() => setOpen(!open)}
      >
        <span>{title}</span>
        <IconChevronUp size={16} stroke={1.8} className={open ? "" : "is-closed"} />
      </button>

      {open && <div className="filter-section__body">{children}</div>}
    </div>
  );
}

/* ===================================
   PÁGINA
=================================== */

function Catalog() {
  const { addItem } = useCart();

  // en pantallas chicas los filtros arrancan ocultos
  const [filtersOpen, setFiltersOpen] = useState(false);

  // rango de precio [mínimo, máximo]
  const [priceRange, setPriceRange] = useState<[number, number]>([0, MAX_PRICE]);

  const [categories, setCategories] = useState<string[]>(["Todo"]);
  const [selectedSizes, setSelectedSizes] = useState<string[]>([]);
  const [selectedColors, setSelectedColors] = useState<string[]>([]); // nombres de color
  const [sortOrder, setSortOrder] = useState<SortOrder>("popular");

  // el header de la tienda muestra el enlace al carrito mientras se está aquí
  useShopHeaderItems();

  // agrega al carrito con la primera talla y el primer color del producto
  const addToCart = (product: Product) => addItem(toCartItem(product));

  // posición de la barra de precio en porcentaje, para pintarla
  const leftPercent = (priceRange[0] / MAX_PRICE) * 100;
  const rightPercent = 100 - (priceRange[1] / MAX_PRICE) * 100;

  // "Todo" y las demás categorías no pueden estar marcadas a la vez
  const toggleCategory = (category: string) => {
    if (category === "Todo") {
      setCategories(["Todo"]);
      return;
    }

    const next = toggleValue(
      categories.filter((item) => item !== "Todo"),
      category,
    );
    setCategories(next.length > 0 ? next : ["Todo"]);
  };

  // deja todos los filtros como al principio
  const clearFilters = () => {
    setCategories(["Todo"]);
    setSelectedSizes([]);
    setSelectedColors([]);
    setPriceRange([0, MAX_PRICE]);
  };

  // productos que cumplen todos los filtros, ya ordenados
  const visibleProducts = useMemo(() => {
    const filtered = PRODUCTS.filter((product) => {
      const matchesCategory =
        categories.includes("Todo") ||
        (product.category !== undefined && categories.includes(product.category));

      const matchesSize =
        selectedSizes.length === 0 ||
        (product.sizes ?? []).some((size) => selectedSizes.includes(size));

      const matchesColor =
        selectedColors.length === 0 ||
        (product.colorNames ?? []).some((color) => selectedColors.includes(color));

      const matchesPrice =
        product.price >= priceRange[0] && product.price <= priceRange[1];

      return matchesCategory && matchesSize && matchesColor && matchesPrice;
    });

    // "popular" deja el orden original; "newest" usa el id más alto como el más reciente
    if (sortOrder === "price-asc") return [...filtered].sort((a, b) => a.price - b.price);
    if (sortOrder === "price-desc") return [...filtered].sort((a, b) => b.price - a.price);
    if (sortOrder === "newest") return [...filtered].sort((a, b) => b.id - a.id);
    return filtered;
  }, [categories, selectedSizes, selectedColors, priceRange, sortOrder]);

  return (
    <main className="catalog-page">
      {/* HERO */}
      <section className="catalog-hero">
        {/* Para poner la foto: .hero-image { background-image: url(...) } en el CSS */}
        <div className="hero-image" />

        <div className="hero-content">
          <span className="hero-subtitle">NUEVA COLECCIÓN</span>

          <h1>Estilo sin límites</h1>

          <p>Prendas que se adaptan a tu historia.</p>

          <button type="button" className="hero-btn">
            Explorar ahora
            <IconArrowRight size={16} stroke={1.8} />
          </button>
        </div>

        <div className="hero-side-text" aria-hidden="true">
          <span>MÁS</span>
          <span>QUE</span>
          <span>ROPA</span>
        </div>
      </section>

      <div className="catalog-container">
        {/* BREADCRUMB */}
        <nav className="catalog-breadcrumb" aria-label="Ruta de navegación">
          <span>Inicio</span>
          <IconChevronRight size={14} stroke={1.8} />
          <span>Catálogo</span>
        </nav>

        <section className="catalog-content">
          {/* botón para mostrar u ocultar los filtros en el celular */}
          <button
            type="button"
            className="filters-toggle"
            aria-expanded={filtersOpen}
            onClick={() => setFiltersOpen(!filtersOpen)}
          >
            <span>Filtros</span>
            <span>{filtersOpen ? "Ocultar" : "Mostrar"}</span>
          </button>

          {/* ---------- FILTROS ---------- */}
          <aside className={`catalog-filters ${filtersOpen ? "is-open" : ""}`}>
            <h3 className="filters-title">Filtrar productos</h3>

            {/* categoría */}
            <FilterSection title="Categoría">
              <ul className="filter-list">
                {CATEGORIES.map((category) => (
                  <li key={category}>
                    <label>
                      <input
                        type="checkbox"
                        checked={categories.includes(category)}
                        onChange={() => toggleCategory(category)}
                      />
                      {category}
                    </label>
                  </li>
                ))}
              </ul>
            </FilterSection>

            {/* talla */}
            <FilterSection title="Talla">
              <div className="sizes">
                {SIZES.map((size) => (
                  <button
                    type="button"
                    key={size}
                    className={selectedSizes.includes(size) ? "is-selected" : ""}
                    aria-pressed={selectedSizes.includes(size)}
                    onClick={() => setSelectedSizes(toggleValue(selectedSizes, size))}
                  >
                    {size}
                  </button>
                ))}
              </div>
            </FilterSection>

            {/* color */}
            <FilterSection title="Color">
              <div className="swatches">
                {FILTER_COLORS.map((color) => (
                  <button
                    type="button"
                    key={color.hex}
                    className={`swatch swatch--filter ${selectedColors.includes(color.name) ? "is-selected" : ""}`}
                    aria-pressed={selectedColors.includes(color.name)}
                    onClick={() => setSelectedColors(toggleValue(selectedColors, color.name))}
                    style={{ background: color.hex }}
                    aria-label={color.name}
                    title={color.name}
                  />
                ))}
              </div>
            </FilterSection>

            {/* precio: dos sliders superpuestos (mínimo y máximo) */}
            <FilterSection title="Precio">
              <div className="range">
                <div className="range__track" />
                <div
                  className="range__fill"
                  style={{ left: `${leftPercent}%`, right: `${rightPercent}%` }}
                />
                <input
                  type="range"
                  min={0}
                  max={MAX_PRICE}
                  step={PRICE_STEP}
                  value={priceRange[0]}
                  aria-label="Precio mínimo"
                  style={{ zIndex: priceRange[0] > MAX_PRICE / 2 ? 5 : 3 }}
                  onChange={(event) =>
                    setPriceRange([
                      Math.min(Number(event.target.value), priceRange[1] - PRICE_STEP),
                      priceRange[1],
                    ])
                  }
                />
                <input
                  type="range"
                  min={0}
                  max={MAX_PRICE}
                  step={PRICE_STEP}
                  value={priceRange[1]}
                  aria-label="Precio máximo"
                  style={{ zIndex: 4 }}
                  onChange={(event) =>
                    setPriceRange([
                      priceRange[0],
                      Math.max(Number(event.target.value), priceRange[0] + PRICE_STEP),
                    ])
                  }
                />
              </div>

              <div className="range__values">
                <span>L {priceRange[0].toLocaleString("en-US")}</span>
                <span>L {priceRange[1].toLocaleString("en-US")}</span>
              </div>
            </FilterSection>

            <button type="button" className="clear-filters" onClick={clearFilters}>
              Limpiar filtros
            </button>
          </aside>

          {/* ---------- PRODUCTOS ---------- */}
          <div className="catalog-products">
            <div className="catalog-header">
              <div className="catalog-title">
                <h2>Catálogo</h2>
                <p>Descubre nuestras prendas y encuentra tu próximo favorito.</p>
              </div>

              <div className="catalog-controls">
                {/* orden */}
                <div className="catalog-sort">
                  <label htmlFor="orden">Ordenar por:</label>
                  <select
                    id="orden"
                    value={sortOrder}
                    onChange={(event) => setSortOrder(event.target.value as SortOrder)}
                  >
                    <option value="popular">Más populares</option>
                    <option value="newest">Más nuevos</option>
                    <option value="price-asc">Precio: menor a mayor</option>
                    <option value="price-desc">Precio: mayor a menor</option>
                  </select>
                </div>

                {/* cuántos productos cumplen los filtros */}
                <span className="catalog-count">
                  {visibleProducts.length}{" "}
                  {visibleProducts.length === 1 ? "producto" : "productos"}
                </span>
              </div>
            </div>

            {/* cuadrícula de tarjetas, o mensaje si nada coincide con los filtros */}
            {visibleProducts.length > 0 ? (
              <div className="products-grid">
                {visibleProducts.map((product) => (
                  <ProductCard
                    key={product.id}
                    product={product}
                    link={`/shop/catalog/product-detail/${product.id}`}
                    onAddToCart={addToCart}
                  />
                ))}
              </div>
            ) : (
              <div className="catalog-empty">
                <h3>No encontramos productos</h3>
                <p>Prueba quitando algún filtro o ampliando el rango de precio.</p>
                <button type="button" onClick={clearFilters}>
                  Limpiar filtros
                </button>
              </div>
            )}
          </div>
        </section>
      </div>
    </main>
  );
}

export default Catalog;
