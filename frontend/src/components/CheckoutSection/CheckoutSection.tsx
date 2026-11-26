import { useId, type ReactNode } from "react";
import "./CheckoutSection.css";

/*
  ┌────────────────────────────────────────┐
  │ [icono]  Título                        │  ← icono, titulo, subtitulo
  │          Subtítulo                     │
  │                                        │
  │ children (campos, opciones, botones)   │  ← lo que pongas dentro
  └────────────────────────────────────────┘
*/

type Props = {
  icono: ReactNode;
  titulo: string;
  subtitulo: string;
  children: ReactNode;
};

function CheckoutSection({ icono, titulo, subtitulo, children }: Props) {
  const idTitulo = useId();

  return (
    <section className="checkout-section" aria-labelledby={idTitulo}>
      <div className="checkout-section__head">
        <span className="checkout-section__icon">{icono}</span>

        <div>
          <h2 id={idTitulo}>{titulo}</h2>
          <p>{subtitulo}</p>
        </div>
      </div>

      <div className="checkout-section__body">{children}</div>
    </section>
  );
}

export default CheckoutSection;
