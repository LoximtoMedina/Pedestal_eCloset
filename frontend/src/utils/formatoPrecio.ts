/**
 * Formatea un número como precio en lempiras.
 * Ejemplo: 1200 → "L 1,200.00"
 */
export const formatPrice = (amount: number) =>
  `L ${amount.toLocaleString("en-US", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;
