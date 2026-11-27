import type { Product } from "../components/ProductCard/ProductCard";
import type { Review } from "../components/ProductTabs/ProductTabs";

/*
  Datos de EJEMPLO. Este archivo hace el papel de la base de datos mientras no hay API:
  cuando exista, las funciones de abajo se reemplazan por consultas y las páginas
  (catálogo y detalle) no necesitan cambiar.
*/

/** Todo lo que muestra la página de detalle de un producto. */
export type ProductDetailData = Product & {
  shortDescription: string; // párrafo bajo el precio
  description: string; // texto largo de la pestaña Descripción
  features: string[]; // viñetas de la pestaña Descripción
  materials: string; // pestaña Materiales
  shipping: string; // pestaña Envíos y devoluciones
  rating: number; // promedio de reseñas
  reviewCount: number;
  reviews: Review[];
  images: string[]; // fotos de la galería; vacío = recuadros "IMG"
  soldOut: string[]; // combinaciones sin stock, con formato "talla|color" (ej. "XL|Beige")
};

/* ---------- productos del catálogo ---------- */

export const PRODUCTS: Product[] = [
  { id: 1, name: "Playera Essential", price: 450, category: "Playeras", tag: "Nuevo", colors: ["#dccfbd", "#111111", "#858585", "#ffffff", "#6b4a36"], colorNames: ["Beige", "Negro", "Gris", "Blanco", "Café"], sizes: ["XS", "S", "M", "L", "XL"] },
  { id: 2, name: "Sudadera Minimal", price: 850, category: "Sudaderas", colors: ["#ffffff", "#858585", "#4d5136"], colorNames: ["Blanco", "Gris", "Verde oliva"], sizes: ["S", "M", "L", "XL"] },
  { id: 3, name: "Pantalón Cargo", price: 950, category: "Pantalones", tag: "Más vendido", colors: ["#6b4a36", "#424a2c", "#111111"], colorNames: ["Café", "Verde oliva", "Negro"], sizes: ["S", "M", "L", "XL"] },
  { id: 4, name: "Gorra Classic", price: 350, category: "Gorras", colors: ["#111111", "#e0e0dd", "#dccfbd"], colorNames: ["Negro", "Gris", "Beige"], sizes: ["Única"] },
  { id: 5, name: "Chaqueta Urban", price: 1200, category: "Chaquetas", colors: ["#2a2a28", "#858585", "#dccfbd"], colorNames: ["Negro", "Gris", "Beige"], sizes: ["S", "M", "L", "XL"] },
  { id: 6, name: "Playera Oversize", price: 550, category: "Playeras", colors: ["#5b5a35", "#858585", "#c9b08a"], colorNames: ["Verde oliva", "Gris", "Beige"], sizes: ["S", "M", "L", "XL"] },
  { id: 7, name: "Short Basic", price: 600, category: "Pantalones", colors: ["#4a3a2e", "#111111"], colorNames: ["Café", "Negro"], sizes: ["S", "M", "L", "XL"] },
  { id: 8, name: "Sudadera Graphic", price: 900, category: "Sudaderas", colors: ["#3d3a35", "#ffffff"], colorNames: ["Gris", "Blanco"], sizes: ["S", "M", "L", "XL"] },
];

/* ---------- textos de ejemplo del detalle ---------- */

const SAMPLE_REVIEWS: Review[] = [
  { author: "Camila R.", rating: 5, date: "12 nov 2026", comment: "Muy cómoda y la tela se siente de buena calidad." },
  { author: "Daniel M.", rating: 5, date: "3 nov 2026", comment: "Queda tal como en las fotos. La talla M me quedó perfecta." },
  { author: "Andrea P.", rating: 4, date: "28 oct 2026", comment: "Me gustó mucho, solo que tardó un poco más de lo esperado en llegar." },
];

const SHIPPING_AND_RETURNS =
  "Envíos a toda Honduras: recibe tu pedido en 2 a 5 días hábiles. " +
  "(Texto de ejemplo: define aquí la política de devoluciones y cambios de Pedestal.)";

/** Campos que solo existen en el detalle (todo lo que no viene de `Product`). */
type ExtraDetail = Omit<ProductDetailData, keyof Product>;

/** Datos del detalle para los productos que no tienen texto propio. */
const genericDetail = (product: Product): ExtraDetail => ({
  shortDescription: `${product.name}, de la colección Pedestal. Cómoda, versátil y con el estilo minimalista de la marca.`,
  description: `${product.name} es una prenda pensada para acompañarte todos los días. Su diseño minimalista combina con cualquier estilo.`,
  features: ["Ajuste regular", "Diseño minimalista", "Disponible en varios colores", "Unisex"],
  materials: "Materiales de calidad. (Texto de ejemplo: indica aquí la composición y el cuidado de la prenda.)",
  shipping: SHIPPING_AND_RETURNS,
  rating: 4.6,
  reviewCount: 12,
  reviews: SAMPLE_REVIEWS,
  images: [],
  soldOut: [],
});

/* ---------- textos propios de algunos productos ---------- */

/** Productos con texto propio (los que no están aquí usan `genericDetail`). */
const PRODUCT_EXTRA: Record<number, Partial<ExtraDetail>> = {
  1: {
    shortDescription:
      "Playera básica de algodón premium, diseñada para acompañarte en cualquier ocasión. Cómoda, versátil y con el estilo minimalista de Pedestal.",
    description:
      "La Playera Essential es una prenda imprescindible en tu guardarropa. Fabricada con algodón de alta calidad, ofrece una sensación suave y fresca durante todo el día. Su diseño minimalista con el logo de Pedestal la hace perfecta para cualquier estilo.",
    features: ["Ajuste regular", "Cuello redondo", "Logo bordado", "Disponible en varios colores", "Unisex"],
    materials: "Algodón premium. (Texto de ejemplo: indica aquí la composición exacta y el cuidado de la prenda.)",
    rating: 4.8,
    reviewCount: 32,
    soldOut: ["XL|Beige", "S|Negro"],
  },
};

/* ---------- consultas ---------- */

/** Un producto con todos sus datos de detalle, o undefined si el id no existe. */
export function getProductDetail(id: number): ProductDetailData | undefined {
  const base = PRODUCTS.find((p) => p.id === id);
  if (!base) return undefined;

  return { ...base, ...genericDetail(base), ...PRODUCT_EXTRA[id] };
}

/** Otros productos, primero los de la misma categoría. */
export function getRelatedProducts(id: number, count = 4): Product[] {
  const current = PRODUCTS.find((p) => p.id === id);
  const others = PRODUCTS.filter((p) => p.id !== id);

  const sameCategory = others.filter((p) => p.category === current?.category);
  const rest = others.filter((p) => p.category !== current?.category);

  return [...sameCategory, ...rest].slice(0, count);
}

/** Agregar rápido desde una tarjeta: usa la primera talla y el primer color del producto. */
export const toCartItem = (product: Product) => ({
  productId: product.id,
  name: product.name,
  price: product.price,
  image: product.image,
  size: product.sizes?.[0] ?? "Única",
  color: product.colorNames?.[0] ?? "Estándar",
});
