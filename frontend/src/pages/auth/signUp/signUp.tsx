/* ==========================================================================
   1. DEPENDENCIAS DE UI, HOOKS Y ESTILOS
   ========================================================================== */
import {
  Anchor,
  Button,
  Checkbox,
  Paper,
  PasswordInput,
  Text,
  TextInput,
  Title,
} from '@mantine/core';
import { useViewportType } from '../../../hooks/useViewportType';
import './signUp.css';

/* ==========================================================================
   2. TIPOS Y CONTRATO DE PROPS
   ========================================================================== */
export interface SignUpData {
  documentoIdentidad: string;
  primerNombre: string;
  segundoNombre: string;
  primerApellido: string;
  segundoApellido: string;
  correo: string;
  telefono: string;
  ciudad: string;
  direccion: string;
  nombreUsuario: string;
  contrasena: string;
  confirmarContrasena: string;
  acceptTerms: boolean;
}

interface SignUpProps {
  onSubmit?: (data: SignUpData) => void;
  onLoginClick?: () => void;
}

/* ==========================================================================
   3. COMPONENTE DE REGISTRO (SIGN UP)
   ========================================================================== */
function SignUp({ onSubmit, onLoginClick }: SignUpProps) {
  const viewport = useViewportType();

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);

    const data: SignUpData = {
      documentoIdentidad: String(formData.get('documentoIdentidad') ?? ''),
      primerNombre: String(formData.get('primerNombre') ?? ''),
      segundoNombre: String(formData.get('segundoNombre') ?? ''),
      primerApellido: String(formData.get('primerApellido') ?? ''),
      segundoApellido: String(formData.get('segundoApellido') ?? ''),
      correo: String(formData.get('correo') ?? ''),
      telefono: String(formData.get('telefono') ?? ''),
      ciudad: String(formData.get('ciudad') ?? ''),
      direccion: String(formData.get('direccion') ?? ''),
      nombreUsuario: String(formData.get('nombreUsuario') ?? ''),
      contrasena: String(formData.get('contrasena') ?? ''),
      confirmarContrasena: String(formData.get('confirmarContrasena') ?? ''),
      acceptTerms: formData.get('acceptTerms') === 'on',
    };

    onSubmit?.(data);
  };

  return (
    <main className={`signUpPage signUpPage--${viewport}`}>
      <div className="signUpWrapper">
        <Paper className="signUpFormCard" component="section" aria-label="Crear cuenta">
          <Title order={2} className="signUpTitle">
            Crea tu cuenta en Pedestal
          </Title>

          {/* Formulario de registro */}
          <form className="signUpForm" onSubmit={handleSubmit}>
            <div className="signUpRow">
              <TextInput
                name="documentoIdentidad"
                label="Documento de identidad"
                placeholder="0000-0000-00000"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />

              <TextInput
                name="telefono"
                type="tel"
                label="Teléfono"
                placeholder="+504 0000-0000"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />
            </div>

            <div className="signUpRow">
              <TextInput
                name="primerNombre"
                label="Primer nombre"
                placeholder="Ej. Carlos"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />

              <TextInput
                name="segundoNombre"
                label="Segundo nombre (opcional)"
                placeholder="Ej. Andrés"
                size="md"
                radius="md"
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />
            </div>

            <div className="signUpRow">
              <TextInput
                name="primerApellido"
                label="Primer apellido"
                placeholder="Ej. Mejía"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />

              <TextInput
                name="segundoApellido"
                label="Segundo apellido (opcional)"
                placeholder="Ej. López"
                size="md"
                radius="md"
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />
            </div>

            <div className="signUpRow">
              <TextInput
                name="correo"
                type="email"
                label="Correo electrónico"
                placeholder="correo@ejemplo.com"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />

              <TextInput
                name="nombreUsuario"
                label="Nombre de usuario"
                placeholder="Ej. carlos.mejia"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />
            </div>

            <div className="signUpRow">
              <TextInput
                name="ciudad"
                label="Ciudad"
                placeholder="Ej. Comayagua"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />

              <TextInput
                name="direccion"
                label="Dirección"
                placeholder="Colonia, calle, referencia"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  input: 'signUpInput',
                }}
              />
            </div>

            <div className="signUpRow">
              <PasswordInput
                name="contrasena"
                label="Contraseña"
                placeholder="Crea una contraseña"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  innerInput: 'signUpInnerInput',
                  input: 'signUpInput',
                }}
              />

              <PasswordInput
                name="confirmarContrasena"
                label="Confirmar contraseña"
                placeholder="Repite tu contraseña"
                size="md"
                radius="md"
                required
                classNames={{
                  root: 'signUpField',
                  label: 'signUpLabel',
                  innerInput: 'signUpInnerInput',
                  input: 'signUpInput',
                }}
              />
            </div>

            <Checkbox
              name="acceptTerms"
              label="Acepto los términos y condiciones"
              size="md"
              required
              classNames={{
                root: 'signUpCheckboxRoot',
                input: 'signUpCheckboxInput',
                label: 'signUpCheckboxLabel',
              }}
            />

            <Button
              type="submit"
              fullWidth
              size="md"
              radius="md"
              classNames={{
                root: 'signUpSubmitBtn',
                label: 'signUpSubmitLabel',
              }}
            >
              Registrarse
            </Button>
          </form>

          {/* Enlace hacia inicio de sesión */}
          <Text className="signUpFooterText">
            ¿Ya tienes una cuenta?{' '}
            <Anchor
              href="/login"
              className="signUpLoginLink"
              onClick={(event) => {
                event.preventDefault();
                onLoginClick?.();
              }}
            >
              Iniciar Sesión
            </Anchor>
          </Text>
        </Paper>

        {/* Panel visual lateral (oculto en mobile) */}
        {viewport !== 'mobile' && (
          <aside className="signUpVisualPanel" aria-hidden="true" />
        )}
      </div>
    </main>
  );
}

export default SignUp;