import {
  useState,
  type ChangeEventHandler,
  type FormEvent,
  type InputHTMLAttributes,
  type ReactNode,
} from "react";

import CheckoutSection from "../../../components/CheckoutSection/CheckoutSection";
import CheckoutSteps from "../../../components/CheckoutSteps/CheckoutSteps";
import OrderSummary from "../../../components/OrderSummary/OrderSummary";
import {
  IconoBanco,
  IconoCamion,
  IconoCandado,
  IconoFlechaDerecha,
  IconoSobre,
  IconoTarjeta,
  IconoUbicacion,
} from "../../../components/icons/icons";
import { formatoPrecio } from "../../../utils/formatoPrecio";
import "./checkout.css";

/* ===================================
   DATOS (por ahora fijos; luego vendrán del carrito y de la base)
=================================== */

// TODO: reemplazar por los productos del carrito compartido (contexto)
type ItemCarrito = {
  id: number;
  nombre: string;
  talla: string;
  color: string;
  precio: number;
  cantidad: number;
};

const ITEMS: ItemCarrito[] = [
  { id: 1, nombre: "Playera Essential", talla: "M", color: "Beige", precio: 450, cantidad: 1 },
  { id: 2, nombre: "Sudadera Minimal", talla: "L", color: "Negro", precio: 850, cantidad: 1 },
  { id: 3, nombre: "Gorra Classic", talla: "Única", color: "Beige", precio: 350, cantidad: 1 },
];

const DEPARTAMENTOS = [
  "Atlántida",
  "Choluteca",
  "Colón",
  "Comayagua",
  "Copán",
  "Cortés",
  "El Paraíso",
  "Francisco Morazán",
  "Gracias a Dios",
  "Intibucá",
  "Islas de la Bahía",
  "La Paz",
  "Lempira",
  "Ocotepeque",
  "Olancho",
  "Santa Bárbara",
  "Valle",
  "Yoro",
];

type MetodoEnvio = "estandar" | "express";
type MetodoPago = "tarjeta" | "transferencia" | "contraentrega";

const ENVIOS: { id: MetodoEnvio; nombre: string; detalle: string; precio: number }[] = [
  { id: "estandar", nombre: "Envío estándar", detalle: "2 a 5 días hábiles", precio: 0 },
  { id: "express", nombre: "Envío express", detalle: "1 a 2 días hábiles", precio: 150 },
];

/* ===================================
   PIEZAS LOCALES DE LA PÁGINA
=================================== */

function Campo({
  id,
  etiqueta,
  ...props
}: { id: string; etiqueta: string } & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <div className="field">
      <label htmlFor={id}>{etiqueta}</label>
      <input id={id} name={id} {...props} />
    </div>
  );
}

function OpcionRadio({
  name,
  value,
  checked,
  onChange,
  titulo,
  detalle,
  children,
}: {
  name: string;
  value: string;
  checked: boolean;
  onChange: ChangeEventHandler<HTMLInputElement>;
  titulo: string;
  detalle?: string;
  children?: ReactNode;
}) {
  return (
    <label className={`opcion ${checked ? "is-selected" : ""}`}>
      <input
        type="radio"
        name={name}
        value={value}
        checked={checked}
        onChange={onChange}
      />

      <span className="opcion__texto">
        <strong>{titulo}</strong>
        {detalle && <small>{detalle}</small>}
      </span>

      {children && <span className="opcion__extra">{children}</span>}
    </label>
  );
}

/* ===================================
   PÁGINA
=================================== */

function Checkout() {
  const [envio, setEnvio] = useState<MetodoEnvio>("estandar");
  const [pago, setPago] = useState<MetodoPago>("tarjeta");

  const costoEnvio = ENVIOS.find((e) => e.id === envio)?.precio ?? 0;

  const manejarEnvio = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const datos = Object.fromEntries(new FormData(e.currentTarget));

    // TODO: guardar estos datos y pasar al paso de revisión del pedido
    console.log({ ...datos, envio, pago });
  };

  return (
    <main className="checkout-page">
      <div className="checkout-container">
        <div className="checkout-head">
          <div>
            <h1>Finalizar compra</h1>
            <p>Completa tus datos para recibir tu pedido.</p>
          </div>

          <CheckoutSteps pasoActual={1} />
        </div>

        <div className="checkout-layout">
          <form className="checkout-forms" onSubmit={manejarEnvio}>
            {/* COLUMNA 1: contacto y dirección */}
            <div className="checkout-col">
              <CheckoutSection
                icono={<IconoSobre size={32} />}
                titulo="Información de contacto"
                subtitulo="Te enviaremos actualizaciones sobre tu pedido."
              >
                <Campo
                  id="correo"
                  etiqueta="Correo electrónico"
                  type="email"
                  placeholder="tu@email.com"
                  autoComplete="email"
                  required
                />

                <label className="check">
                  <input type="checkbox" name="ofertas" defaultChecked />
                  Quiero recibir ofertas y novedades de Pedestal
                </label>
              </CheckoutSection>

              <CheckoutSection
                icono={<IconoUbicacion size={32} />}
                titulo="Dirección de envío"
                subtitulo="Ingresa la dirección donde recibirás tu pedido."
              >
                <Campo
                  id="nombre"
                  etiqueta="Nombre completo"
                  placeholder="Tu nombre"
                  autoComplete="name"
                  required
                />

                <div className="field-row">
                  <Campo
                    id="telefono"
                    etiqueta="Teléfono"
                    type="tel"
                    placeholder="+504 9999-9999"
                    autoComplete="tel"
                    required
                  />

                  <div className="field">
                    <label htmlFor="departamento">Departamento</label>
                    <select id="departamento" name="departamento" defaultValue="" required>
                      <option value="" disabled>
                        Selecciona
                      </option>
                      {DEPARTAMENTOS.map((d) => (
                        <option key={d} value={d}>
                          {d}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <Campo
                  id="ciudad"
                  etiqueta="Ciudad / Municipio"
                  placeholder="Ej. Tegucigalpa"
                  autoComplete="address-level2"
                  required
                />

                <Campo
                  id="direccion"
                  etiqueta="Dirección"
                  placeholder="Dirección exacta"
                  autoComplete="address-line1"
                  required
                />

                <Campo
                  id="referencia"
                  etiqueta="Referencia (opcional)"
                  placeholder="Ej. Casa blanca, frente al parque"
                />
              </CheckoutSection>
            </div>

            {/* COLUMNA 2: envío y pago */}
            <div className="checkout-col">
              <CheckoutSection
                icono={<IconoCamion size={32} />}
                titulo="Método de envío"
                subtitulo="Selecciona la opción que más te convenga."
              >
                <fieldset className="opciones">
                  <legend className="sr-only">Método de envío</legend>

                  {ENVIOS.map((e) => (
                    <OpcionRadio
                      key={e.id}
                      name="envio"
                      value={e.id}
                      checked={envio === e.id}
                      onChange={() => setEnvio(e.id)}
                      titulo={e.nombre}
                      detalle={e.detalle}
                    >
                      {e.precio === 0 ? "Gratis" : formatoPrecio(e.precio)}
                    </OpcionRadio>
                  ))}
                </fieldset>
              </CheckoutSection>

              <CheckoutSection
                icono={<IconoTarjeta size={32} />}
                titulo="Método de pago"
                subtitulo="Selecciona tu método de pago."
              >
                <fieldset className="opciones">
                  <legend className="sr-only">Método de pago</legend>

                  <OpcionRadio
                    name="pago"
                    value="tarjeta"
                    checked={pago === "tarjeta"}
                    onChange={() => setPago("tarjeta")}
                    titulo="Tarjeta de crédito o débito"
                  >
                    <span className="marcas" aria-hidden="true">
                      <span className="marca marca--visa">VISA</span>
                      <span className="marca-mc">
                        <i />
                        <i />
                      </span>
                      <span className="marca marca--amex">AMEX</span>
                    </span>
                  </OpcionRadio>

                  <OpcionRadio
                    name="pago"
                    value="transferencia"
                    checked={pago === "transferencia"}
                    onChange={() => setPago("transferencia")}
                    titulo="Transferencia bancaria"
                  >
                    <IconoBanco size={24} />
                  </OpcionRadio>

                  <OpcionRadio
                    name="pago"
                    value="contraentrega"
                    checked={pago === "contraentrega"}
                    onChange={() => setPago("contraentrega")}
                    titulo="Pago contra entrega"
                    detalle="Paga cuando recibas tu pedido."
                  />
                </fieldset>

                <p className="secure">
                  <IconoCandado size={16} />
                  Tus datos están protegidos con cifrado SSL.
                </p>

                <button type="submit" className="checkout-btn">
                  Revisar pedido
                  <IconoFlechaDerecha size={20} />
                </button>
              </CheckoutSection>
            </div>
          </form>

          <OrderSummary items={ITEMS} costoEnvio={costoEnvio} />
        </div>
      </div>
    </main>
  );
}

export default Checkout;
