import type { CSSProperties } from "react";
import "./StarRating.css";

type Props = {
  valor: number; // calificación de 0 a 5 (admite decimales: 4.8 pinta casi 5 estrellas)
  tamano?: number; // tamaño en px
};

function StarRating({ valor, tamano = 16 }: Props) {
  return (
    <span
      className="star-rating"
      role="img"
      aria-label={`${valor} de 5 estrellas`}
      style={{ fontSize: tamano }}
    >
      {[0, 1, 2, 3, 4].map((i) => {
        const relleno = Math.max(0, Math.min(1, valor - i)) * 100;

        return (
          <span
            key={i}
            className="star-rating__star"
            style={{ "--relleno": `${relleno}%` } as CSSProperties}
          />
        );
      })}
    </span>
  );
}

export default StarRating;
