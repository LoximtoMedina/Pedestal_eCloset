import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router";
import {
  IconArrowRight,
  IconChevronRight,
  IconCreditCard,
  IconHeadset,
  IconMinus,
  IconPackage,
  IconPlus,
  IconShieldCheck,
  IconShoppingBag,
  IconTruckDelivery,
} from "@tabler/icons-react";
import ProductCard from "../../../components/ProductCard/ProductCard";
import ProductGallery from "../../../components/ProductGallery/ProductGallery";
import ProductTabs from "../../../components/ProductTabs/ProductTabs";
import StarRating from "../../../components/StarRating/StarRating";
import { useCart } from "../../../context/CartContext";
import {
  getProductDetail,
  getRelatedProducts,
  toCartItem,
  type ProductDetailData,
} from "../../../data/productos";
import { formatPrice } from "../../../utils/formatoPrecio";
import "./productDetail.css";

// ruta base del detalle: se le agrega el id del producto
const DETAIL_ROUTE = "/shop/catalog/product-detail";

// máximo de unidades que se pueden pedir de una vez
const MAX_QUANTITY = 10;

// beneficios que se listan al lado de la ficha
const BENEFITS = [
  {
    Icon: IconTruckDelivery,
    title: "Envíos a toda Honduras",
    text: "Recibe tu pedido en 2 a 5 días hábiles.",
  },
  {
    Icon: IconPackage,
    title: "Empaque de calidad",
    text: "Tus productos llegan protegidos en perfectas condiciones.",
  },
  {
    Icon: IconShieldCheck,
    title: "Compra segura",
    text: "Tus datos están protegidos.",
  },
  {
    Icon: IconCreditCard,
    title: "Múltiples métodos de pago",
    text: "Tarjeta, transferencia o contra entrega.",
  },
];

/* ===================================
   CONTENIDO DEL PRODUCTO
   (se vuelve a crear desde cero cuando cambia el producto, por el `key` de abajo)
=================================== */

function ProductDetailView({ product }: { product: ProductDetailData }) {
  const navigate = useNavigate();
  const { addItem } = useCart();

  const sizes = product.sizes ?? ["Única"];
  const colorNames = product.colorNames ?? product.colors.map(() => "Único");

  /* ---------- disponibilidad: una combinación talla+color puede estar agotada ---------- */
  const isSoldOut = (size: string, color: string) =>
    product.soldOut.includes(`${size}|${color}`);

  const firstAvailableSize = (color: string) =>
    sizes.find((size) => !isSoldOut(size, color));

  const isColorAvailable = (color: string) =>
    sizes.some((size) => !isSoldOut(size, color));

  /* ---------- selección del cliente ---------- */
  const [colorIndex, setColorIndex] = useState(
    Math.max(0, colorNames.findIndex(isColorAvailable)),
  );
  const colorName = colorNames[colorIndex];

  const [selectedSize, setSelectedSize] = useState(
    firstAvailableSize(colorName) ?? sizes[0],
  );
  const [quantity, setQuantity] = useState(1);
  const [added, setAdded] = useState(false);

  const outOfStock = isSoldOut(selectedSize, colorName);

  // cada vez que se abre un producto, la página arranca desde arriba
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  // si la talla elegida se agota en el color nuevo, pasa a la primera disponible
  const selectColor = (index: number) => {
    const name = colorNames[index];
    setColorIndex(index);
    if (isSoldOut(selectedSize, name)) {
      setSelectedSize(firstAvailableSize(name) ?? selectedSize);
    }
  };

  /* ---------- carrito ---------- */
  const buildItem = () => ({
    productId: product.id,
    name: product.name,
    price: product.price,
    image: product.images[0],
    size: selectedSize,
    color: colorName,
    quantity,
  });

  const addToCart = () => {
    addItem(buildItem());
    setAdded(true);
    window.setTimeout(() => setAdded(false), 1800);
  };

  const buyNow = () => {
    addItem(buildItem());
    navigate("/shop/cart/checkout");
  };

  const relatedProducts = getRelatedProducts(product.id, 4);

  return (
    <main className="detail-page">
      <div className="detail-container">
        {/* MIGAS DE PAN */}
        <nav className="detail-breadcrumb" aria-label="Ruta de navegación">
          <Link to="/">Inicio</Link>
          <IconChevronRight size={14} stroke={1.8} />
          <Link to="/shop/catalog">Catálogo</Link>
          <IconChevronRight size={14} stroke={1.8} />
          {product.category && (
            <>
              <span>{product.category}</span>
              <IconChevronRight size={14} stroke={1.8} />
            </>
          )}
          <span aria-current="page">{product.name}</span>
        </nav>

        <section className="detail-layout">
          {/* ---------- columna izquierda: galería de fotos ---------- */}
          <ProductGallery images={product.images} name={product.name} />

          {/* ---------- columna central: ficha y compra ---------- */}
          <div className="detail-info">
            {product.tag && (
              <span className="detail-badge">{product.tag.toUpperCase()}</span>
            )}

            <h1>{product.name}</h1>
            <p className="detail-price">{formatPrice(product.price)}</p>

            {/* calificación promedio */}
            <div className="detail-rating">
              <StarRating value={product.rating} />
              <span>
                <strong>{product.rating.toFixed(1)}</strong> ({product.reviewCount}{" "}
                reseñas)
              </span>
            </div>

            <p className="detail-summary">{product.shortDescription}</p>

            {/* COLOR */}
            <div className="detail-option">
              <p className="detail-label">
                Color: <span>{colorName}</span>
              </p>
              <div className="detail-colors">
                {product.colors.map((hex, index) => {
                  const name = colorNames[index];
                  const available = isColorAvailable(name);

                  return (
                    <button
                      type="button"
                      key={hex}
                      className={`detail-swatch ${index === colorIndex ? "is-selected" : ""}`}
                      style={{ background: hex }}
                      aria-label={available ? name : `${name} (agotado)`}
                      aria-pressed={index === colorIndex}
                      title={name}
                      disabled={!available}
                      onClick={() => selectColor(index)}
                    />
                  );
                })}
              </div>
            </div>

            {/* TALLA */}
            <div className="detail-option">
              <p className="detail-label">Talla:</p>
              <div className="detail-sizes">
                {sizes.map((size) => (
                  <button
                    type="button"
                    key={size}
                    className={size === selectedSize ? "is-selected" : ""}
                    aria-pressed={size === selectedSize}
                    disabled={isSoldOut(size, colorName)}
                    onClick={() => setSelectedSize(size)}
                  >
                    {size}
                  </button>
                ))}
              </div>
            </div>

            {/* CANTIDAD */}
            <div className="detail-option detail-qty-row">
              <p className="detail-label">Cantidad:</p>
              <div className="detail-qty" role="group" aria-label="Cantidad">
                <button
                  type="button"
                  aria-label="Reducir cantidad"
                  disabled={quantity <= 1}
                  onClick={() => setQuantity(quantity - 1)}
                >
                  <IconMinus size={16} stroke={2} />
                </button>
                <span aria-live="polite">{quantity}</span>
                <button
                  type="button"
                  aria-label="Aumentar cantidad"
                  disabled={quantity >= MAX_QUANTITY}
                  onClick={() => setQuantity(quantity + 1)}
                >
                  <IconPlus size={16} stroke={2} />
                </button>
              </div>
            </div>

            {/* BOTONES DE COMPRA */}
            <div className="detail-actions">
              <button
                type="button"
                className="detail-btn detail-btn--primary"
                disabled={outOfStock}
                onClick={addToCart}
              >
                <IconShoppingBag size={20} stroke={1.8} />
                Agregar al carrito
              </button>

              <button
                type="button"
                className="detail-btn detail-btn--outline"
                disabled={outOfStock}
                onClick={buyNow}
              >
                Comprar ahora
              </button>
            </div>

            <p className="detail-status" role="status">
              {outOfStock
                ? "Agotado en esta combinación"
                : added
                  ? "Agregado al carrito ✓"
                  : ""}
            </p>
          </div>

          {/* ---------- columna derecha: beneficios y ayuda ---------- */}
          <aside className="detail-aside">
            <div className="detail-card detail-benefits">
              {BENEFITS.map(({ Icon, title, text }) => (
                <div className="detail-benefit" key={title}>
                  <Icon size={32} stroke={1.6} />
                  <div>
                    <h3>{title}</h3>
                    <p>{text}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="detail-card detail-help">
              <IconHeadset size={32} stroke={1.6} />
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
          description={product.description}
          features={product.features}
          materials={product.materials}
          shipping={product.shipping}
          rating={product.rating}
          reviewCount={product.reviewCount}
          reviews={product.reviews}
        />

        {/* RELACIONADOS */}
        <section className="detail-related">
          <div className="detail-related__head">
            <h2>Productos relacionados</h2>
            <Link to="/shop/catalog">
              Ver más
              <IconArrowRight size={16} stroke={1.8} />
            </Link>
          </div>

          <div className="detail-related__grid">
            {relatedProducts.map((item) => (
              <ProductCard
                key={item.id}
                product={item}
                link={`${DETAIL_ROUTE}/${item.id}`}
                onAddToCart={(p) => addItem(toCartItem(p))}
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

function ProductDetailPage() {
  const { id } = useParams();
  const product = getProductDetail(Number(id));

  // si el id no existe, se muestra el mensaje de no encontrado
  if (!product) {
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
  return <ProductDetailView key={product.id} product={product} />;
}

export default ProductDetailPage;
