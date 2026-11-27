import { IconShoppingBag } from "@tabler/icons-react";
import { Link } from "react-router";
import { formatPrice } from "../../utils/formatoPrecio";
import "./ProductCard.css";

/*
  Dónde va cada dato en la tarjeta:

  ┌──────────────────────────┐
  │ [etiqueta]               │  ← insignia opcional
  │          imagen          │  ← imagen
  ├──────────────────────────┤
  │ nombre                   │  ← nombre
  │ L precio                 │  ← precio
  │ ● ● ● colores       [🛍]  │  ← colores + botón de carrito
  └──────────────────────────┘
*/

/** Un producto tal como se muestra en la tarjeta. Cada campo saldrá de la base de datos. */
export type Product = {
  id: number; // identificador único del producto
  name: string; // nombre que ve el cliente
  price: number; // precio de venta en lempiras
  category?: string; // categoría ("Playeras", "Gorras"...); sirve para filtrar
  tag?: "Nuevo" | "Más vendido"; // insignia opcional (arriba a la izquierda)
  colors: string[]; // colores disponibles en hex, cada uno es un círculo
  image?: string; // ruta de la foto principal; si falta se muestra "IMG"
  sizes?: string[]; // tallas disponibles; la primera se usa al agregar desde la tarjeta
  colorNames?: string[]; // nombre de cada color de `colors`, en el mismo orden
};

type ProductCardProps = {
  product: Product;
  link?: string; // si se da, la imagen y el nombre llevan a esa ruta (detalle del producto)
  onAddToCart?: (product: Product) => void; // al tocar el botón de carrito
};

function ProductCard({ product, link, onAddToCart }: ProductCardProps) {
  const { name, price, tag, colors, image } = product;

  /* ---------- imagen o recuadro "IMG" ---------- */
  const imageContent = image ? (
    <img src={image} alt={name} loading="lazy" />
  ) : (
    <span className="product-card__placeholder">IMG</span>
  );

  return (
    <article className="product-card">
      {/* ---------- media: insignia + foto + botón de carrito superpuesto ---------- */}
      <div className="product-card__media">
        {tag && <span className="product-card__badge">{tag}</span>}

        {link ? (
          <Link to={link} className="product-card__image-link" aria-label={`Ver ${name}`}>
            {imageContent}
          </Link>
        ) : (
          imageContent
        )}
      </div>

      {/* ---------- info: nombre, precio, colores y agregar ---------- */}
      <div className="product-card__info">
        <h3 className="product-card__name" title={name}>
          {link ? <Link to={link}>{name}</Link> : name}
        </h3>

        <p className="product-card__price">{formatPrice(price)}</p>

        <div className="product-card__footer">
          <div className="product-card__colors">
            {colors.map((hex) => (
              <span key={hex} className="product-card__swatch" style={{ background: hex }} />
            ))}
          </div>

          <button
            type="button"
            className="product-card__cart"
            aria-label={`Agregar ${name} al carrito`}
            onClick={() => onAddToCart?.(product)}
          >
            <IconShoppingBag size={20} stroke={1.8} />
          </button>
        </div>
      </div>
    </article>
  );
}

export default ProductCard;
