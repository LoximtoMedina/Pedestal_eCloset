import { useState } from "react";
import {
  IconoChevronAbajo,
  IconoChevronArriba,
  IconoLupa,
} from "../icons/icons";
import "./ProductGallery.css";

/*
  ┌────┬──────────────────────┐
  │ ▲  │                      │
  │ 1  │                      │  ← miniaturas (la elegida se marca)
  │ 2  │      foto grande     │  ← foto elegida
  │ 3  │                  🔍  │
  │ ▼  │                      │
  └────┴──────────────────────┘
*/

type Props = {
  imagenes: string[]; // rutas de las fotos; si está vacío se muestran 4 recuadros "IMG"
  nombre: string; // nombre del producto, para el texto alternativo
};

function ProductGallery({ imagenes, nombre }: Props) {
  const fotos: (string | null)[] =
    imagenes.length > 0 ? imagenes : [null, null, null, null];

  const [actual, setActual] = useState(0);

  const mover = (delta: number) =>
    setActual((actual + delta + fotos.length) % fotos.length);

  return (
    <div className="gallery">
      <div className="gallery__thumbs">
        <button
          type="button"
          className="gallery__arrow"
          aria-label="Foto anterior"
          onClick={() => mover(-1)}
        >
          <IconoChevronArriba />
        </button>

        {fotos.map((foto, i) => (
          <button
            type="button"
            key={i}
            className={`gallery__thumb ${i === actual ? "is-active" : ""}`}
            aria-label={`Ver foto ${i + 1}`}
            aria-current={i === actual}
            onClick={() => setActual(i)}
          >
            {foto ? <img src={foto} alt="" /> : <span>{i + 1}</span>}
          </button>
        ))}

        <button
          type="button"
          className="gallery__arrow"
          aria-label="Foto siguiente"
          onClick={() => mover(1)}
        >
          <IconoChevronAbajo />
        </button>
      </div>

      <div className="gallery__main">
        {fotos[actual] ? (
          <img src={fotos[actual]!} alt={`${nombre}, foto ${actual + 1}`} />
        ) : (
          <span>IMG</span>
        )}

        {/* TODO: abrir la foto en grande */}
        <button type="button" className="gallery__zoom" aria-label="Ampliar imagen">
          <IconoLupa />
        </button>
      </div>
    </div>
  );
}

export default ProductGallery;
