import {
  useId,
  useState,
  type ChangeEventHandler,
  type FormEvent,
  type InputHTMLAttributes,
  type ReactNode,
} from "react";
import { Link } from "react-router";
import {
  IconArrowLeft,
  IconArrowRight,
  IconBuildingBank,
  IconCheck,
  IconCreditCard,
  IconLock,
  IconMail,
  IconMapPin,
  IconPackage,
  IconShieldCheck,
  IconShoppingBag,
  IconTruckDelivery,
} from "@tabler/icons-react";
import { useCart, type CartLine } from "../../../context/CartContext";
import { formatPrice } from "../../../utils/formatoPrecio";
import "./checkout.css";

/* ===================================
   DATOS (por ahora fijos; luego vendrán de la base)
=================================== */

// departamentos de Honduras para el selector de dirección
const DEPARTMENTS = [
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

type ShippingMethod = "standard" | "express";
type PaymentMethod = "card" | "transfer" | "cash";

// opciones de envío: precio 0 = gratis
const SHIPPING_OPTIONS: {
  id: ShippingMethod;
  name: string;
  detail: string;
  price: number;
}[] = [
  { id: "standard", name: "Envío estándar", detail: "2 a 5 días hábiles", price: 0 },
  { id: "express", name: "Envío express", detail: "1 a 2 días hábiles", price: 150 },
];

// pasos que se ven arriba a la derecha
const CHECKOUT_STEPS = ["Información", "Envío", "Pago", "Confirmación"];

/* ===================================
   PIEZAS DE LA PÁGINA
=================================== */

/** Un campo de texto con su etiqueta. */
function Field({
  id,
  label,
  ...props
}: { id: string; label: string } & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      <input id={id} name={id} {...props} />
    </div>
  );
}

/** Una opción con botón de radio (envío o pago). */
function RadioOption({
  name,
  value,
  checked,
  onChange,
  title,
  detail,
  children,
}: {
  name: string;
  value: string;
  checked: boolean;
  onChange: ChangeEventHandler<HTMLInputElement>;
  title: string;
  detail?: string;
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
        <strong>{title}</strong>
        {detail && <small>{detail}</small>}
      </span>

      {children && <span className="opcion__extra">{children}</span>}
    </label>
  );
}

/** Tarjeta con icono, título y subtítulo que envuelve un grupo de campos. */
function CheckoutSection({
  icon,
  title,
  subtitle,
  children,
}: {
  icon: ReactNode;
  title: string;
  subtitle: string;
  children: ReactNode;
}) {
  const titleId = useId();

  return (
    <section className="checkout-section" aria-labelledby={titleId}>
      <div className="checkout-section__head">
        <span className="checkout-section__icon">{icon}</span>

        <div>
          <h2 id={titleId}>{title}</h2>
          <p>{subtitle}</p>
        </div>
      </div>

      <div className="checkout-section__body">{children}</div>
    </section>
  );
}

/** Línea de pasos: los ya hechos llevan un check, el actual va resaltado. */
function CheckoutSteps({ currentStep }: { currentStep: 1 | 2 | 3 | 4 }) {
  return (
    <ol className="checkout-steps" aria-label="Pasos de la compra">
      {CHECKOUT_STEPS.map((name, index) => {
        const stepNumber = index + 1;
        const state =
          stepNumber < currentStep
            ? "done"
            : stepNumber === currentStep
              ? "current"
              : "pending";

        return (
          <li
            key={name}
            className={`checkout-steps__item is-${state}`}
            aria-current={state === "current" ? "step" : undefined}
          >
            <span className="checkout-steps__circle">
              {state === "done" ? <IconCheck size={16} stroke={2} /> : stepNumber}
            </span>
            <span className="checkout-steps__label">{name}</span>
          </li>
        );
      })}
    </ol>
  );
}

/** Beneficios que se repiten debajo del resumen del pedido. */
const SUMMARY_BENEFITS = [
  {
    Icon: IconTruckDelivery,
    title: "Envíos a toda Honduras",
    text: "Recibe tu pedido en 2 a 5 días hábiles.",
  },
  {
    Icon: IconPackage,
    title: "Empaque de calidad",
    text: "Tus productos llegan protegidos.",
  },
  {
    Icon: IconShieldCheck,
    title: "Compra segura",
    text: "Tus datos están protegidos.",
  },
];

/** Columna derecha: productos del carrito, subtotal, envío y total. */
function OrderSummaryPanel({
  items,
  shippingCost,
}: {
  items: CartLine[];
  shippingCost: number;
}) {
  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const total = subtotal + shippingCost;

  return (
    <aside className="order-summary" aria-label="Resumen del pedido">
      <div className="order-summary__head">
        <IconShoppingBag size={26} stroke={1.8} />
        <h2>Resumen del pedido</h2>
        <Link to="/shop/cart" className="order-summary__link">
          Editar carrito
        </Link>
      </div>

      {/* un renglón por producto */}
      <ul className="order-summary__items">
        {items.map((item) => (
          <li key={item.id} className="order-summary__item">
            <div className="order-summary__thumb">
              {item.image && <img src={item.image} alt={item.name} loading="lazy" />}
            </div>

            <div>
              <p className="order-summary__name">{item.name}</p>
              <p className="order-summary__meta">
                Talla {item.size} · {item.color}
              </p>
              <p className="order-summary__price">{formatPrice(item.price)}</p>
            </div>

            <span className="order-summary__qty">x{item.quantity}</span>
          </li>
        ))}
      </ul>

      <div className="order-summary__row">
        <span>Subtotal</span>
        <span>{formatPrice(subtotal)}</span>
      </div>

      <div className="order-summary__row">
        <span>Envío</span>
        <span>{shippingCost === 0 ? "Gratis" : formatPrice(shippingCost)}</span>
      </div>

      <div className="order-summary__total">
        <span>Total</span>
        <span>{formatPrice(total)}</span>
      </div>

      <div className="order-summary__benefits">
        {SUMMARY_BENEFITS.map(({ Icon, title, text }) => (
          <div className="order-summary__benefit" key={title}>
            <Icon size={28} stroke={1.6} />
            <div>
              <h3>{title}</h3>
              <p>{text}</p>
            </div>
          </div>
        ))}
      </div>

      <Link to="/shop/cart" className="order-summary__back">
        <IconArrowLeft size={18} stroke={1.8} />
        Volver al carrito
      </Link>
    </aside>
  );
}

/* ===================================
   PÁGINA
=================================== */

function Checkout() {
  const [shipping, setShipping] = useState<ShippingMethod>("standard");
  const [payment, setPayment] = useState<PaymentMethod>("card");
  const { items } = useCart();

  const shippingCost = SHIPPING_OPTIONS.find((o) => o.id === shipping)?.price ?? 0;

  // al enviar el formulario se juntan todos los campos escritos
  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = Object.fromEntries(new FormData(event.currentTarget));

    // TODO: guardar estos datos y pasar al paso de revisión del pedido
    console.log({ ...formData, shipping, payment });
  };

  return (
    <main className="checkout-page">
      <div className="checkout-container">
        {/* encabezado con el paso actual */}
        <div className="checkout-head">
          <div>
            <h1>Finalizar compra</h1>
            <p>Completa tus datos para recibir tu pedido.</p>
          </div>

          <CheckoutSteps currentStep={1} />
        </div>

        <div className="checkout-layout">
          <form className="checkout-forms" onSubmit={handleSubmit}>
            {/* ---------- columna 1: contacto y dirección ---------- */}
            <div className="checkout-col">
              <CheckoutSection
                icon={<IconMail size={32} stroke={1.6} />}
                title="Información de contacto"
                subtitle="Te enviaremos actualizaciones sobre tu pedido."
              >
                <Field
                  id="correo"
                  label="Correo electrónico"
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
                icon={<IconMapPin size={32} stroke={1.6} />}
                title="Dirección de envío"
                subtitle="Ingresa la dirección donde recibirás tu pedido."
              >
                <Field
                  id="nombre"
                  label="Nombre completo"
                  placeholder="Tu nombre"
                  autoComplete="name"
                  required
                />

                <div className="field-row">
                  <Field
                    id="telefono"
                    label="Teléfono"
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
                      {DEPARTMENTS.map((department) => (
                        <option key={department} value={department}>
                          {department}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <Field
                  id="ciudad"
                  label="Ciudad / Municipio"
                  placeholder="Ej. Tegucigalpa"
                  autoComplete="address-level2"
                  required
                />

                <Field
                  id="direccion"
                  label="Dirección"
                  placeholder="Dirección exacta"
                  autoComplete="address-line1"
                  required
                />

                <Field
                  id="referencia"
                  label="Referencia (opcional)"
                  placeholder="Ej. Casa blanca, frente al parque"
                />
              </CheckoutSection>
            </div>

            {/* ---------- columna 2: envío y pago ---------- */}
            <div className="checkout-col">
              <CheckoutSection
                icon={<IconTruckDelivery size={32} stroke={1.6} />}
                title="Método de envío"
                subtitle="Selecciona la opción que más te convenga."
              >
                <fieldset className="opciones">
                  <legend className="sr-only">Método de envío</legend>

                  {SHIPPING_OPTIONS.map((option) => (
                    <RadioOption
                      key={option.id}
                      name="envio"
                      value={option.id}
                      checked={shipping === option.id}
                      onChange={() => setShipping(option.id)}
                      title={option.name}
                      detail={option.detail}
                    >
                      {option.price === 0 ? "Gratis" : formatPrice(option.price)}
                    </RadioOption>
                  ))}
                </fieldset>
              </CheckoutSection>

              <CheckoutSection
                icon={<IconCreditCard size={32} stroke={1.6} />}
                title="Método de pago"
                subtitle="Selecciona tu método de pago."
              >
                <fieldset className="opciones">
                  <legend className="sr-only">Método de pago</legend>

                  <RadioOption
                    name="pago"
                    value="card"
                    checked={payment === "card"}
                    onChange={() => setPayment("card")}
                    title="Tarjeta de crédito o débito"
                  >
                    <span className="marcas" aria-hidden="true">
                      <span className="marca marca--visa">VISA</span>
                      <span className="marca-mc">
                        <i />
                        <i />
                      </span>
                      <span className="marca marca--amex">AMEX</span>
                    </span>
                  </RadioOption>

                  <RadioOption
                    name="pago"
                    value="transfer"
                    checked={payment === "transfer"}
                    onChange={() => setPayment("transfer")}
                    title="Transferencia bancaria"
                  >
                    <IconBuildingBank size={24} stroke={1.6} />
                  </RadioOption>

                  <RadioOption
                    name="pago"
                    value="cash"
                    checked={payment === "cash"}
                    onChange={() => setPayment("cash")}
                    title="Pago contra entrega"
                    detail="Paga cuando recibas tu pedido."
                  />
                </fieldset>

                <p className="secure">
                  <IconLock size={16} stroke={1.8} />
                  Tus datos están protegidos con cifrado SSL.
                </p>

                <button type="submit" className="checkout-btn">
                  Revisar pedido
                  <IconArrowRight size={20} stroke={1.8} />
                </button>
              </CheckoutSection>
            </div>
          </form>

          {/* ---------- columna 3: resumen ---------- */}
          <OrderSummaryPanel items={items} shippingCost={shippingCost} />
        </div>
      </div>
    </main>
  );
}

export default Checkout;
