import { useState } from "react";
import StarRating from "../StarRating/StarRating";
import "./ProductTabs.css";

/** Una reseña de un cliente. Cada campo saldrá de la base de datos. */
export type Resena = {
  autor: string;
  calificacion: number; // de 1 a 5
  fecha: string;
  comentario: string;
};

type Props = {
  descripcion: string; // texto largo de la pestaña Descripción
  caracteristicas: string[]; // viñetas dentro de la pestaña Descripción
  materiales: string; // pestaña Materiales
  envios: string; // pestaña Envíos y devoluciones
  calificacion: number; // promedio, por ejemplo 4.8
  totalResenas: number; // cuántas reseñas hay en total
  resenas: Resena[]; // las reseñas que se muestran
};

type Pestana = "descripcion" | "materiales" | "envios" | "resenas";

function ProductTabs({
  descripcion,
  caracteristicas,
  materiales,
  envios,
  calificacion,
  totalResenas,
  resenas,
}: Props) {
  const [activa, setActiva] = useState<Pestana>("descripcion");

  const pestanas: { id: Pestana; titulo: string }[] = [
    { id: "descripcion", titulo: "Descripción" },
    { id: "materiales", titulo: "Materiales" },
    { id: "envios", titulo: "Envíos y devoluciones" },
    { id: "resenas", titulo: `Reseñas (${totalResenas})` },
  ];

  return (
    <section className="product-tabs">
      <div className="product-tabs__list" role="tablist" aria-label="Información del producto">
        {pestanas.map((p) => (
          <button
            key={p.id}
            type="button"
            role="tab"
            id={`tab-${p.id}`}
            aria-selected={activa === p.id}
            aria-controls={`panel-${p.id}`}
            className={activa === p.id ? "is-active" : ""}
            onClick={() => setActiva(p.id)}
          >
            {p.titulo}
          </button>
        ))}
      </div>

      <div
        className="product-tabs__panel"
        role="tabpanel"
        id={`panel-${activa}`}
        aria-labelledby={`tab-${activa}`}
      >
        {activa === "descripcion" && (
          <>
            <p>{descripcion}</p>
            <ul className="product-tabs__features">
              {caracteristicas.map((c) => (
                <li key={c}>{c}</li>
              ))}
            </ul>
          </>
        )}

        {activa === "materiales" && <p>{materiales}</p>}

        {activa === "envios" && <p>{envios}</p>}

        {activa === "resenas" && (
          <div>
            <div className="reviews__summary">
              <strong>{calificacion.toFixed(1)}</strong>
              <StarRating valor={calificacion} tamano={20} />
              <span>{totalResenas} reseñas</span>
            </div>

            <ul className="reviews__list">
              {resenas.map((r) => (
                <li key={`${r.autor}-${r.fecha}`} className="reviews__item">
                  <div className="reviews__meta">
                    <strong>{r.autor}</strong>
                    <StarRating valor={r.calificacion} tamano={14} />
                    <span>{r.fecha}</span>
                  </div>
                  <p>{r.comentario}</p>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </section>
  );
}

export default ProductTabs;
