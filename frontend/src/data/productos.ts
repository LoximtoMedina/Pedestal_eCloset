import type { Producto } from "../components/ProductCard/ProductCard";
import type { Resena } from "../components/ProductTabs/ProductTabs";

/*
  Datos de EJEMPLO. Este archivo hace el papel de la base de datos mientras no hay API:
  cuando exista, las funciones de abajo se reemplazan por consultas y las páginas
  (catálogo y detalle) no necesitan cambiar.
*/

/** Todo lo que muestra la página de detalle de un producto. */
export type ProductoDetalle = Producto & {
  descripcionCorta: string; // párrafo bajo el precio
  descripcion: string; // texto largo de la pestaña Descripción
  caracteristicas: string[]; // viñetas de la pestaña Descripción
  materiales: string; // pestaña Materiales
  envios: string; // pestaña Envíos y devoluciones
  calificacion: number; // promedio de reseñas
  totalResenas: number;
  resenas: Resena[];
  imagenes: string[]; // fotos de la galería; vacío = recuadros "IMG"
  agotados: string[]; // combinaciones sin stock, con formato "talla|color" (ej. "XL|Beige")
};

export const PRODUCTOS: Producto[] = [
  { id: 1, nombre: "Playera Essential", precio: 450, categoria: "Playeras", etiqueta: "Nuevo", colores: ["#dccfbd", "#111111", "#858585", "#ffffff", "#6b4a36"], coloresNombre: ["Beige", "Negro", "Gris", "Blanco", "Café"], tallas: ["XS", "S", "M", "L", "XL"] },
  { id: 2, nombre: "Sudadera Minimal", precio: 850, categoria: "Sudaderas", colores: ["#ffffff", "#858585", "#4d5136"], coloresNombre: ["Blanco", "Gris", "Verde oliva"], tallas: ["S", "M", "L", "XL"] },
  { id: 3, nombre: "Pantalón Cargo", precio: 950, categoria: "Pantalones", etiqueta: "Más vendido", colores: ["#6b4a36", "#424a2c", "#111111"], coloresNombre: ["Café", "Verde oliva", "Negro"], tallas: ["S", "M", "L", "XL"] },
  { id: 4, nombre: "Gorra Classic", precio: 350, categoria: "Gorras", colores: ["#111111", "#e0e0dd", "#dccfbd"], coloresNombre: ["Negro", "Gris", "Beige"], tallas: ["Única"] },
  { id: 5, nombre: "Chaqueta Urban", precio: 1200, categoria: "Chaquetas", colores: ["#2a2a28", "#858585", "#dccfbd"], coloresNombre: ["Negro", "Gris", "Beige"], tallas: ["S", "M", "L", "XL"] },
  { id: 6, nombre: "Playera Oversize", precio: 550, categoria: "Playeras", colores: ["#5b5a35", "#858585", "#c9b08a"], coloresNombre: ["Verde oliva", "Gris", "Beige"], tallas: ["S", "M", "L", "XL"] },
  { id: 7, nombre: "Short Basic", precio: 600, categoria: "Pantalones", colores: ["#4a3a2e", "#111111"], coloresNombre: ["Café", "Negro"], tallas: ["S", "M", "L", "XL"] },
  { id: 8, nombre: "Sudadera Graphic", precio: 900, categoria: "Sudaderas", colores: ["#3d3a35", "#ffffff"], coloresNombre: ["Gris", "Blanco"], tallas: ["S", "M", "L", "XL"] },
];

/* ---------- textos de ejemplo del detalle ---------- */

const RESENAS_EJEMPLO: Resena[] = [
  { autor: "Camila R.", calificacion: 5, fecha: "12 nov 2026", comentario: "Muy cómoda y la tela se siente de buena calidad." },
  { autor: "Daniel M.", calificacion: 5, fecha: "3 nov 2026", comentario: "Queda tal como en las fotos. La talla M me quedó perfecta." },
  { autor: "Andrea P.", calificacion: 4, fecha: "28 oct 2026", comentario: "Me gustó mucho, solo que tardó un poco más de lo esperado en llegar." },
];

const ENVIOS_Y_DEVOLUCIONES =
  "Envíos a toda Honduras: recibe tu pedido en 2 a 5 días hábiles. " +
  "(Texto de ejemplo: define aquí la política de devoluciones y cambios de Pedestal.)";

type DatosExtra = Omit<ProductoDetalle, keyof Producto>;

/** Datos del detalle para los productos que no tienen texto propio. */
const generico = (p: Producto): DatosExtra => ({
  descripcionCorta: `${p.nombre}, de la colección Pedestal. Cómoda, versátil y con el estilo minimalista de la marca.`,
  descripcion: `${p.nombre} es una prenda pensada para acompañarte todos los días. Su diseño minimalista combina con cualquier estilo.`,
  caracteristicas: ["Ajuste regular", "Diseño minimalista", "Disponible en varios colores", "Unisex"],
  materiales: "Materiales de calidad. (Texto de ejemplo: indica aquí la composición y el cuidado de la prenda.)",
  envios: ENVIOS_Y_DEVOLUCIONES,
  calificacion: 4.6,
  totalResenas: 12,
  resenas: RESENAS_EJEMPLO,
  imagenes: [],
  agotados: [],
});

/** Productos con texto propio (el resto usa `generico`). */
const EXTRA: Record<number, Partial<DatosExtra>> = {
  1: {
    descripcionCorta:
      "Playera básica de algodón premium, diseñada para acompañarte en cualquier ocasión. Cómoda, versátil y con el estilo minimalista de Pedestal.",
    descripcion:
      "La Playera Essential es una prenda imprescindible en tu guardarropa. Fabricada con algodón de alta calidad, ofrece una sensación suave y fresca durante todo el día. Su diseño minimalista con el logo de Pedestal la hace perfecta para cualquier estilo.",
    caracteristicas: ["Ajuste regular", "Cuello redondo", "Logo bordado", "Disponible en varios colores", "Unisex"],
    materiales: "Algodón premium. (Texto de ejemplo: indica aquí la composición exacta y el cuidado de la prenda.)",
    calificacion: 4.8,
    totalResenas: 32,
    agotados: ["XL|Beige", "S|Negro"],
  },
};

/* ---------- consultas ---------- */

/** Un producto con todos sus datos de detalle, o undefined si el id no existe. */
export function obtenerDetalle(id: number): ProductoDetalle | undefined {
  const base = PRODUCTOS.find((p) => p.id === id);
  if (!base) return undefined;

  return { ...base, ...generico(base), ...EXTRA[id] };
}

/** Otros productos, primero los de la misma categoría. */
export function productosRelacionados(id: number, cantidad = 4): Producto[] {
  const actual = PRODUCTOS.find((p) => p.id === id);
  const otros = PRODUCTOS.filter((p) => p.id !== id);

  const misma = otros.filter((p) => p.categoria === actual?.categoria);
  const resto = otros.filter((p) => p.categoria !== actual?.categoria);

  return [...misma, ...resto].slice(0, cantidad);
}

/** Agregar rápido desde una tarjeta: usa la primera talla y el primer color del producto. */
export const aItemCarrito = (p: Producto) => ({
  productoId: p.id,
  nombre: p.nombre,
  precio: p.precio,
  imagen: p.imagen,
  talla: p.tallas?.[0] ?? "Única",
  color: p.coloresNombre?.[0] ?? "Estándar",
});
