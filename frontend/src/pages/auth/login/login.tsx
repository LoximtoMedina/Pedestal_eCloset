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

interface LoginProps {
  onSubmit?: (credentials: {
    email: string;
    password: string;
    rememberMe: boolean;
  }) => void;
  onRegisterClick?: () => void;
}

function Login({ onSubmit, onRegisterClick }: LoginProps) {
  const viewport = useViewportType();

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const email = String(formData.get('email') ?? '');
    const password = String(formData.get('password') ?? '');
    const rememberMe = formData.get('rememberMe') === 'on';

    onSubmit?.({ email, password, rememberMe });
  };

  return (
    <main className={`loginPage loginPage--${viewport}`}>
      <div className="loginWrapper">
        <Paper className="loginFormCard" component="section" aria-label="Iniciar sesión">
          <Title order={2} className="loginTitle">
            Bienvenido a PEDESTAL
          </Title>

          <form className="loginForm" onSubmit={handleSubmit}>
            <TextInput
              name="email"
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

          <Text className="loginFooterText">
            ¿No tienes una cuenta?{' '}
            <Anchor
              href="#register"
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

        {viewport !== 'mobile' && (
          <aside className="loginVisualPanel" aria-hidden="true" />
        )}
      </div>
    </main>
  );
}

export default Login;