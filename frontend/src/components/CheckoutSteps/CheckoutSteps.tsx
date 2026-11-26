import { IconoCheck } from "../icons/icons";
import "./CheckoutSteps.css";

const PASOS = ["Información", "Envío", "Pago", "Confirmación"];

type Props = {
  /** Paso en el que está el cliente: 1 Información, 2 Envío, 3 Pago, 4 Confirmación */
  pasoActual: 1 | 2 | 3 | 4;
};

function CheckoutSteps({ pasoActual }: Props) {
  return (
    <ol className="checkout-steps" aria-label="Pasos de la compra">
      {PASOS.map((nombre, i) => {
        const numero = i + 1;
        const estado =
          numero < pasoActual ? "done" : numero === pasoActual ? "current" : "pending";

        return (
          <li
            key={nombre}
            className={`checkout-steps__item is-${estado}`}
            aria-current={estado === "current" ? "step" : undefined}
          >
            <span className="checkout-steps__circle">
              {estado === "done" ? <IconoCheck size={16} /> : numero}
            </span>
            <span className="checkout-steps__label">{nombre}</span>
          </li>
        );
      })}
    </ol>
  );
}

export default CheckoutSteps;
