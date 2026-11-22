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
import './login.css';

/* ==========================================================================
   2. TIPOS Y CONTRATO DE PROPS
   ========================================================================== */
export interface LoginCredentials {
  email: string;
  password: string;
  rememberMe: boolean;
}

interface LoginProps {
  onSubmit?: (credentials: LoginCredentials) => void;
  onRegisterClick?: () => void;
}

/* ==========================================================================
   3. COMPONENTE DE INICIO DE SESIÓN (LOGIN)
   ========================================================================== */
function Login({ onSubmit, onRegisterClick }: LoginProps) {
  const viewport = useViewportType();

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);

    const credentials: LoginCredentials = {
      email: String(formData.get('email') ?? '').trim(),
      password: String(formData.get('password') ?? ''),
      rememberMe: formData.get('rememberMe') === 'on',
    };

    onSubmit?.(credentials);
  };

  return (
    <main className={`loginPage loginPage--${viewport}`}>
      <div className="loginWrapper">
        <Paper className="loginFormCard" component="section" aria-label="Iniciar sesión">
          <Title order={2} className="loginTitle">
            Bienvenido a Pedestal
          </Title>

          {/* Formulario de acceso */}
          <form className="loginForm" onSubmit={handleSubmit}>
            <TextInput
              name="email"
              type="email"
              label="Correo electrónico"
              placeholder="correo@ejemplo.com"
              size="md"
              radius="md"
              required
              classNames={{
                root: 'loginField',
                label: 'loginLabel',
                input: 'loginInput',
              }}
            />

            <PasswordInput
              name="password"
              label="Contraseña"
              placeholder="Tu contraseña"
              size="md"
              radius="md"
              required
              classNames={{
                root: 'loginField',
                label: 'loginLabel',
                innerInput: 'loginInnerInput',
                input: 'loginInput',
              }}
            />

            <Checkbox
              name="rememberMe"
              label="Mantener sesión iniciada"
              size="md"
              classNames={{
                root: 'loginCheckboxRoot',
                input: 'loginCheckboxInput',
                label: 'loginCheckboxLabel',
              }}
            />

            <Button
              type="submit"
              fullWidth
              size="md"
              radius="md"
              classNames={{
                root: 'loginSubmitBtn',
                label: 'loginSubmitLabel',
              }}
            >
              Iniciar Sesión
            </Button>
          </form>

          {/* Enlace hacia registro */}
          <Text className="loginFooterText">
            ¿No tienes una cuenta?{' '}
            <Anchor
              href="/signup"
              className="loginRegisterLink"
              onClick={(event) => {
                event.preventDefault();
                onRegisterClick?.();
              }}
            >
              Registrarse
            </Anchor>
          </Text>
        </Paper>

        {/* Panel visual lateral (oculto en mobile) */}
        {viewport !== 'mobile' && (
          <aside className="loginVisualPanel" aria-hidden="true" />
        )}
      </div>
    </main>
  );
}

export default Login;