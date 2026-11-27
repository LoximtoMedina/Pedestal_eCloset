import { useMemo, useState, type ReactNode } from "react";
import ProductCard, {
  type Producto,
} from "../../../components/ProductCard/ProductCard";
import { useCart } from "../../../context/CartContext";
import { PRODUCTOS, aItemCarrito } from "../../../data/productos";
import { useShopHeaderItems } from "../../../hooks/useShopHeaderItems";
import "./catalog.css";

/* ===================================
   DATOS (por ahora fijos; luego vendrán de la base)
=================================== */

const PRECIO_MAX = 2000;
const PRECIO_PASO = 50;

const CATEGORIAS = [
  "Todo",
  "Playeras",
  "Sudaderas",
  "Pantalones",
  "Accesorios",
  "Gorras",
  "Chaquetas",
];

const TALLAS = ["XS", "S", "M", "L", "XL"];

const COLORES_FILTRO = [
  { nombre: "Negro", hex: "#111111" },
  { nombre: "Blanco", hex: "#ffffff" },
  { nombre: "Gris", hex: "#858585" },
  { nombre: "Beige", hex: "#dccfbd" },
  { nombre: "Verde oliva", hex: "#4d5136" },
  { nombre: "Café", hex: "#6b4a36" },
];

type Orden = "populares" | "nuevos" | "precio-asc" | "precio-desc";

/** Agrega el valor a la lista si no está, o lo quita si ya está. */
const alternar = (lista: string[], valor: string) =>
  lista.includes(valor) ? lista.filter((v) => v !== valor) : [...lista, valor];

/* ===================================
   ÍCONOS (SVG propios, sin librerías)
=================================== */

function Icono({
  children,
  size = 20,
  className,
}: {
  children: ReactNode;
  size?: number;
  className?: string;
}) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {children}
    </svg>
  );
}

const IconoFlechaDerecha = () => (
  <Icono size={16}>
    <path d="M5 12h14" />
    <path d="m12 5 7 7-7 7" />
  </Icono>
);

const IconoChevronDerecha = () => (
  <Icono size={14}>
    <path d="m9 18 6-6-6-6" />
  </Icono>
);

/* ===================================
   SECCIÓN COLAPSABLE DE FILTROS
=================================== */

function SeccionFiltro({
  titulo,
  children,
}: {
  titulo: string;
  children: ReactNode;
}) {
  const [abierta, setAbierta] = useState(true);

  return (
    <div className="filter-section">
      <button
        type="button"
        className="filter-section__head"
        aria-expanded={abierta}
        onClick={() => setAbierta(!abierta)}
      >
        <span>{titulo}</span>
        <Icono size={16} className={abierta ? "" : "is-closed"}>
          <path d="m18 15-6-6-6 6" />
        </Icono>
      </button>

      {abierta && <div className="filter-section__body">{children}</div>}
    </div>
  );
}

/* ===================================
   PÁGINA
=================================== */

function Catalog() {
  const [filtrosAbiertos, setFiltrosAbiertos] = useState(false);

  const { agregar } = useCart();

  const agregarAlCarrito = (p: Producto) => agregar(aItemCarrito(p));

  useShopHeaderItems();

  const [precio, setPrecio] = useState<[number, number]>([0, PRECIO_MAX]);

  const izquierda = (precio[0] / PRECIO_MAX) * 100;
  const derecha = 100 - (precio[1] / PRECIO_MAX) * 100;

  const [categorias, setCategorias] = useState<string[]>(["Todo"]);
  const [tallasSel, setTallasSel] = useState<string[]>([]);
  const [coloresSel, setColoresSel] = useState<string[]>([]); // nombres de color
  const [orden, setOrden] = useState<Orden>("populares");

  // "Todo" y las demás categorías no pueden estar marcadas a la vez
  const alternarCategoria = (cat: string) => {
    if (cat === "Todo") {
      setCategorias(["Todo"]);
      return;
    }

    const nuevas = alternar(
      categorias.filter((c) => c !== "Todo"),
      cat,
    );
    setCategorias(nuevas.length > 0 ? nuevas : ["Todo"]);
  };

  const limpiarFiltros = () => {
    setCategorias(["Todo"]);
    setTallasSel([]);
    setColoresSel([]);
    setPrecio([0, PRECIO_MAX]);
  };

  const productosVisibles = useMemo(() => {
    const filtrados = PRODUCTOS.filter((p) => {
      const cumpleCategoria =
        categorias.includes("Todo") ||
        (p.categoria !== undefined && categorias.includes(p.categoria));

      const cumpleTalla =
        tallasSel.length === 0 || (p.tallas ?? []).some((t) => tallasSel.includes(t));

      const cumpleColor =
        coloresSel.length === 0 ||
        (p.coloresNombre ?? []).some((c) => coloresSel.includes(c));

      const cumplePrecio = p.precio >= precio[0] && p.precio <= precio[1];

      return cumpleCategoria && cumpleTalla && cumpleColor && cumplePrecio;
    });

    // "populares" deja el orden original; "nuevos" usa el id más alto como el más reciente
    if (orden === "precio-asc") return [...filtrados].sort((x, y) => x.precio - y.precio);
    if (orden === "precio-desc") return [...filtrados].sort((x, y) => y.precio - x.precio);
    if (orden === "nuevos") return [...filtrados].sort((x, y) => y.id - x.id);
    return filtrados;
  }, [categorias, tallasSel, coloresSel, precio, orden]);

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
            <IconoFlechaDerecha />
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
          <IconoChevronDerecha />
          <span>Catálogo</span>
        </nav>

        <section className="catalog-content">
          {/* FILTROS */}
          <button
            type="button"
            className="filters-toggle"
            aria-expanded={filtrosAbiertos}
            onClick={() => setFiltrosAbiertos(!filtrosAbiertos)}
          >
            <span>Filtros</span>
            <span>{filtrosAbiertos ? "Ocultar" : "Mostrar"}</span>
          </button>

          <aside className={`catalog-filters ${filtrosAbiertos ? "is-open" : ""}`}>
            <h3 className="filters-title">Filtrar productos</h3>

            <SeccionFiltro titulo="Categoría">
              <ul className="filter-list">
                {CATEGORIAS.map((cat) => (
                  <li key={cat}>
                    <label>
                      <input
                        type="checkbox"
                        checked={categorias.includes(cat)}
                        onChange={() => alternarCategoria(cat)}
                      />
                      {cat}
                    </label>
                  </li>
                ))}
              </ul>
            </SeccionFiltro>

            <SeccionFiltro titulo="Talla">
              <div className="sizes">
                {TALLAS.map((talla) => (
                  <button
                    type="button"
                    key={talla}
                    className={tallasSel.includes(talla) ? "is-selected" : ""}
                    aria-pressed={tallasSel.includes(talla)}
                    onClick={() => setTallasSel(alternar(tallasSel, talla))}
                  >
                    {talla}
                  </button>
                ))}
              </div>
            </SeccionFiltro>

            <SeccionFiltro titulo="Color">
              <div className="swatches">
                {COLORES_FILTRO.map((c) => (
                  <button
                    type="button"
                    key={c.hex}
                    className={`swatch swatch--filter ${coloresSel.includes(c.nombre) ? "is-selected" : ""}`}
                    aria-pressed={coloresSel.includes(c.nombre)}
                    onClick={() => setColoresSel(alternar(coloresSel, c.nombre))}
                    style={{ background: c.hex }}
                    aria-label={c.nombre}
                    title={c.nombre}
                  />
                ))}
              </div>
            </SeccionFiltro>

            <SeccionFiltro titulo="Precio">
              <div className="range">
                <div className="range__track" />
                <div
                  className="range__fill"
                  style={{ left: `${izquierda}%`, right: `${derecha}%` }}
                />
                <input
                  type="range"
                  min={0}
                  max={PRECIO_MAX}
                  step={PRECIO_PASO}
                  value={precio[0]}
                  aria-label="Precio mínimo"
                  style={{ zIndex: precio[0] > PRECIO_MAX / 2 ? 5 : 3 }}
                  onChange={(e) =>
                    setPrecio([
                      Math.min(Number(e.target.value), precio[1] - PRECIO_PASO),
                      precio[1],
                    ])
                  }
                />
                <input
                  type="range"
                  min={0}
                  max={PRECIO_MAX}
                  step={PRECIO_PASO}
                  value={precio[1]}
                  aria-label="Precio máximo"
                  style={{ zIndex: 4 }}
                  onChange={(e) =>
                    setPrecio([
                      precio[0],
                      Math.max(Number(e.target.value), precio[0] + PRECIO_PASO),
                    ])
                  }
                />
              </div>

              <div className="range__values">
                <span>L {precio[0].toLocaleString("en-US")}</span>
                <span>L {precio[1].toLocaleString("en-US")}</span>
              </div>
            </SeccionFiltro>

            <button type="button" className="clear-filters" onClick={limpiarFiltros}>
              Limpiar filtros
            </button>
          </aside>

          {/* PRODUCTOS */}
          <div className="catalog-products">
            <div className="catalog-header">
              <div className="catalog-title">
                <h2>Catálogo</h2>
                <p>Descubre nuestras prendas y encuentra tu próximo favorito.</p>
              </div>

              <div className="catalog-controls">
                <div className="catalog-sort">
                  <label htmlFor="orden">Ordenar por:</label>
                  <select
                    id="orden"
                    value={orden}
                    onChange={(e) => setOrden(e.target.value as Orden)}
                  >
                    <option value="populares">Más populares</option>
                    <option value="nuevos">Más nuevos</option>
                    <option value="precio-asc">Precio: menor a mayor</option>
                    <option value="precio-desc">Precio: mayor a menor</option>
                  </select>
                </div>

                <span className="catalog-count">
                  {productosVisibles.length}{" "}
                  {productosVisibles.length === 1 ? "producto" : "productos"}
                </span>
              </div>
            </div>

            {productosVisibles.length > 0 ? (
              <div className="products-grid">
                {productosVisibles.map((p) => (
                  <ProductCard
                    key={p.id}
                    producto={p}
                    enlace={`/shop/catalog/product-detail/${p.id}`}
                    onAgregarCarrito={agregarAlCarrito}
                  />
                ))}
              </div>
            ) : (
              <div className="catalog-empty">
                <h3>No encontramos productos</h3>
                <p>Prueba quitando algún filtro o ampliando el rango de precio.</p>
                <button type="button" onClick={limpiarFiltros}>
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