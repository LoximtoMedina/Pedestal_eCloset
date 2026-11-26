/** Formatea un número como precio en lempiras: 1200 → "L 1,200.00" */
export const formatoPrecio = (n: number) =>
  `L ${n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
