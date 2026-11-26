import "./productCard.css";

/*
  Dónde va cada dato en la tarjeta:

  ┌──────────────────────────┐
  │ [etiqueta]            ♥  │  ← etiqueta + botón de favoritos
  │          imagen          │  ← imagen
  ├──────────────────────────┤
  │ nombre                   │  ← nombre
  │ L precio                 │  ← precio
  │ ● ● ● colores       [🛍]  │  ← colores + botón de carrito
  └──────────────────────────┘
*/

/** Un producto tal como se muestra en la tarjeta. Cada campo saldrá de la base de datos. */
export type Producto = {
  id: number; // identificador único del producto
  nombre: string; // nombre que ve el cliente
  precio: number; // precio de venta en lempiras
  etiqueta?: "Nuevo" | "Más vendido"; // insignia opcional (arriba a la izquierda)
  colores: string[]; // colores disponibles en hex, cada uno es un círculo
  imagen?: string; // ruta de la foto principal; si falta se muestra "IMG"
};

type Props = {
  producto: Producto;
  onToggleFavorito?: (producto: Producto) => void; // al tocar el corazón
  onAgregarCarrito?: (producto: Producto) => void; // al tocar el carrito
};

const formatoPrecio = (n: number) =>
  `L ${n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

function ProductCard({ producto, onToggleFavorito, onAgregarCarrito }: Props) {
  const { nombre, precio, etiqueta, colores, imagen } = producto;

  return (
    <article className="product-card">
      <div className="product-card__media">
        {etiqueta && <span className="product-card__badge">{etiqueta}</span>}

        <button
          type="button"
          className="product-card__fav"
          aria-label={`Guardar ${nombre} en favoritos`}
          onClick={() => onToggleFavorito?.(producto)}
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
          </svg>
        </button>

        {imagen ? (
          <img src={imagen} alt={nombre} loading="lazy" />
        ) : (
          <span className="product-card__placeholder">IMG</span>
        )}
      </div>

      <div className="product-card__info">
        <h3 className="product-card__name" title={nombre}>
          {nombre}
        </h3>

        <p className="product-card__price">{formatoPrecio(precio)}</p>

        <div className="product-card__footer">
          <div className="product-card__colors">
            {colores.map((hex) => (
              <span
                key={hex}
                className="product-card__swatch"
                style={{ background: hex }}
              />
            ))}
          </div>

          <button
            type="button"
            className="product-card__cart"
            aria-label={`Agregar ${nombre} al carrito`}
            onClick={() => onAgregarCarrito?.(producto)}
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.8"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" />
              <path d="M3 6h18" />
              <path d="M16 10a4 4 0 0 1-8 0" />
            </svg>
          </button>
        </div>
      </div>
    </article>
  );
}

export default ProductCard;