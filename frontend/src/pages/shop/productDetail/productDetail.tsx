import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router";
import ProductCard from "../../../components/ProductCard/ProductCard";
import ProductGallery from "../../../components/ProductGallery/ProductGallery";
import ProductTabs from "../../../components/ProductTabs/ProductTabs";
import StarRating from "../../../components/StarRating/StarRating";
import {
  IconoAuricular,
  IconoBolsa,
  IconoCaja,
  IconoCamion,
  IconoChevronDerecha,
  IconoCorazon,
  IconoEscudo,
  IconoFlechaDerecha,
  IconoMas,
  IconoMenos,
  IconoRegla,
  IconoTarjeta,
} from "../../../components/icons/icons";
import { useCart } from "../../../context/CartContext";
import {
  aItemCarrito,
  obtenerDetalle,
  productosRelacionados,
  type ProductoDetalle,
} from "../../../data/productos";
import { formatoPrecio } from "../../../utils/formatoPrecio";
import "./productDetail.css";

const RUTA_DETALLE = "/shop/catalog/product-detail";
const CANTIDAD_MAX = 10;

const BENEFICIOS = [
  { Icono: IconoCamion, titulo: "Envíos a toda Honduras", texto: "Recibe tu pedido en 2 a 5 días hábiles." },
  { Icono: IconoCaja, titulo: "Empaque de calidad", texto: "Tus productos llegan protegidos en perfectas condiciones." },
  { Icono: IconoEscudo, titulo: "Compra segura", texto: "Tus datos están protegidos." },
  { Icono: IconoTarjeta, titulo: "Múltiples métodos de pago", texto: "Tarjeta, transferencia o contra entrega." },
];

/* ===================================
   CONTENIDO DEL PRODUCTO
   (se vuelve a crear desde cero cuando cambia el producto, por el `key` de abajo)
=================================== */

function DetalleProducto({ producto }: { producto: ProductoDetalle }) {
  const navigate = useNavigate();
  const { agregar } = useCart();

  const tallas = producto.tallas ?? ["Única"];
  const nombresColor = producto.coloresNombre ?? producto.colores.map(() => "Único");

  const agotado = (talla: string, color: string) =>
    producto.agotados.includes(`${talla}|${color}`);
  const tallaDisponible = (color: string) => tallas.find((t) => !agotado(t, color));
  const colorDisponible = (color: string) => tallas.some((t) => !agotado(t, color));

  const [colorIdx, setColorIdx] = useState(
    Math.max(0, nombresColor.findIndex(colorDisponible)),
  );
  const colorNombre = nombresColor[colorIdx];
  const [talla, setTalla] = useState(tallaDisponible(colorNombre) ?? tallas[0]);
  const [cantidad, setCantidad] = useState(1);
  const [agregado, setAgregado] = useState(false);

  const sinStock = agotado(talla, colorNombre);

  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  // si la talla elegida se agota en el color nuevo, pasa a la primera disponible
  const elegirColor = (i: number) => {
    const nombre = nombresColor[i];
    setColorIdx(i);
    if (agotado(talla, nombre)) setTalla(tallaDisponible(nombre) ?? talla);
  };

  const nuevoItem = () => ({
    productoId: producto.id,
    nombre: producto.nombre,
    precio: producto.precio,
    imagen: producto.imagenes[0],
    talla,
    color: colorNombre,
    cantidad,
  });

  const agregarAlCarrito = () => {
    agregar(nuevoItem());
    setAgregado(true);
    window.setTimeout(() => setAgregado(false), 1800);
  };

  const comprarAhora = () => {
    agregar(nuevoItem());
    navigate("/shop/cart/checkout");
  };

  const relacionados = productosRelacionados(producto.id, 4);

  return (
    <main className="detail-page">
      <div className="detail-container">
        {/* MIGAS DE PAN */}
        <nav className="detail-breadcrumb" aria-label="Ruta de navegación">
          <Link to="/">Inicio</Link>
          <IconoChevronDerecha size={14} />
          <Link to="/shop/catalog">Catálogo</Link>
          <IconoChevronDerecha size={14} />
          {producto.categoria && (
            <>
              <span>{producto.categoria}</span>
              <IconoChevronDerecha size={14} />
            </>
          )}
          <span aria-current="page">{producto.nombre}</span>
        </nav>

        <section className="detail-layout">
          <ProductGallery imagenes={producto.imagenes} nombre={producto.nombre} />

          {/* INFORMACIÓN Y COMPRA */}
          <div className="detail-info">
            {producto.etiqueta && (
              <span className="detail-badge">{producto.etiqueta.toUpperCase()}</span>
            )}

            <h1>{producto.nombre}</h1>
            <p className="detail-price">{formatoPrecio(producto.precio)}</p>

            <div className="detail-rating">
              <StarRating valor={producto.calificacion} />
              <span>
                <strong>{producto.calificacion.toFixed(1)}</strong> ({producto.totalResenas}{" "}
                reseñas)
              </span>
            </div>

            <p className="detail-summary">{producto.descripcionCorta}</p>

            {/* COLOR */}
            <div className="detail-option">
              <p className="detail-label">
                Color: <span>{colorNombre}</span>
              </p>
              <div className="detail-colors">
                {producto.colores.map((hex, i) => {
                  const nombre = nombresColor[i];
                  const disponible = colorDisponible(nombre);

                  return (
                    <button
                      type="button"
                      key={hex}
                      className={`detail-swatch ${i === colorIdx ? "is-selected" : ""}`}
                      style={{ background: hex }}
                      aria-label={disponible ? nombre : `${nombre} (agotado)`}
                      aria-pressed={i === colorIdx}
                      title={nombre}
                      disabled={!disponible}
                      onClick={() => elegirColor(i)}
                    />
                  );
                })}
              </div>
            </div>

            {/* TALLA */}
            <div className="detail-option">
              <p className="detail-label">Talla:</p>
              <div className="detail-sizes">
                {tallas.map((t) => (
                  <button
                    type="button"
                    key={t}
                    className={t === talla ? "is-selected" : ""}
                    aria-pressed={t === talla}
                    disabled={agotado(t, colorNombre)}
                    onClick={() => setTalla(t)}
                  >
                    {t}
                  </button>
                ))}

                {/* TODO: abrir la guía de tallas */}
                <button type="button" className="detail-guide">
                  <IconoRegla size={18} />
                  Guía de tallas
                </button>
              </div>
            </div>

            {/* CANTIDAD */}
            <div className="detail-option detail-qty-row">
              <p className="detail-label">Cantidad:</p>
              <div className="detail-qty" role="group" aria-label="Cantidad">
                <button
                  type="button"
                  aria-label="Reducir cantidad"
                  disabled={cantidad <= 1}
                  onClick={() => setCantidad(cantidad - 1)}
                >
                  <IconoMenos size={16} />
                </button>
                <span aria-live="polite">{cantidad}</span>
                <button
                  type="button"
                  aria-label="Aumentar cantidad"
                  disabled={cantidad >= CANTIDAD_MAX}
                  onClick={() => setCantidad(cantidad + 1)}
                >
                  <IconoMas size={16} />
                </button>
              </div>
            </div>

            {/* BOTONES */}
            <div className="detail-actions">
              <button
                type="button"
                className="detail-btn detail-btn--primary"
                disabled={sinStock}
                onClick={agregarAlCarrito}
              >
                <IconoBolsa size={20} />
                Agregar al carrito
              </button>

              <button
                type="button"
                className="detail-btn detail-btn--outline"
                disabled={sinStock}
                onClick={comprarAhora}
              >
                Comprar ahora
              </button>
            </div>

            <p className="detail-status" role="status">
              {sinStock ? "Agotado en esta combinación" : agregado ? "Agregado al carrito ✓" : ""}
            </p>

            {/* TODO: guardar en favoritos (necesita sesión) */}
            <button type="button" className="detail-fav">
              <IconoCorazon size={20} />
              Agregar a favoritos
            </button>
          </div>

          {/* BENEFICIOS Y AYUDA */}
          <aside className="detail-aside">
            <div className="detail-card detail-benefits">
              {BENEFICIOS.map(({ Icono, titulo, texto }) => (
                <div className="detail-benefit" key={titulo}>
                  <Icono size={32} />
                  <div>
                    <h3>{titulo}</h3>
                    <p>{texto}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="detail-card detail-help">
              <IconoAuricular size={32} />
              <div>
                <h3>¿Necesitas ayuda?</h3>
                <p>Contáctanos por WhatsApp o correo.</p>
                {/* TODO: enlazar a WhatsApp o correo */}
                <button type="button">Contactar</button>
              </div>
            </div>
          </aside>
        </section>

        {/* PESTAÑAS */}
        <ProductTabs
          descripcion={producto.descripcion}
          caracteristicas={producto.caracteristicas}
          materiales={producto.materiales}
          envios={producto.envios}
          calificacion={producto.calificacion}
          totalResenas={producto.totalResenas}
          resenas={producto.resenas}
        />

        {/* RELACIONADOS */}
        <section className="detail-related">
          <div className="detail-related__head">
            <h2>Productos relacionados</h2>
            <Link to="/shop/catalog">
              Ver más
              <IconoFlechaDerecha size={16} />
            </Link>
          </div>

          <div className="detail-related__grid">
            {relacionados.map((p) => (
              <ProductCard
                key={p.id}
                producto={p}
                enlace={`${RUTA_DETALLE}/${p.id}`}
                onAgregarCarrito={(prod) => agregar(aItemCarrito(prod))}
              />
            ))}
          </div>
        </section>
      </div>
    </main>
  );
}

/* ===================================
   PÁGINA: busca el producto por el id de la ruta
=================================== */

function ProductDetail() {
  const { id } = useParams();
  const producto = obtenerDetalle(Number(id));

  if (!producto) {
    return (
      <main className="detail-page">
        <div className="detail-container detail-missing">
          <h1>Producto no encontrado</h1>
          <p>Es posible que ya no esté disponible.</p>
          <Link to="/shop/catalog">Volver al catálogo</Link>
        </div>
      </main>
    );
  }

  // el key reinicia color, talla y cantidad al pasar de un producto a otro
  return <DetalleProducto key={producto.id} producto={producto} />;
}

export default ProductDetail;
