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

interface SignUpData {
  name: string;
  email: string;
  password: string;
  confirmPassword: string;
  acceptTerms: boolean;
}

interface SignUpProps {
  onSubmit?: (data: SignUpData) => void;
  onLoginClick?: () => void;
}

function SignUp({ onSubmit, onLoginClick }: SignUpProps) {
  const viewport = useViewportType();

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);

    const name = String(formData.get('name') ?? '');
    const email = String(formData.get('email') ?? '');
    const password = String(formData.get('password') ?? '');
    const confirmPassword = String(formData.get('confirmPassword') ?? '');
    const acceptTerms = formData.get('acceptTerms') === 'on';

    onSubmit?.({ name, email, password, confirmPassword, acceptTerms });
  };

  return (
    <main className={`signUpPage signUpPage--${viewport}`}>
      <div className="signUpWrapper">
        <Paper className="signUpFormCard" component="section" aria-label="Crear cuenta">
          <Title order={2} className="signUpTitle">
            Crea tu cuenta en PEDESTAL
          </Title>

          <form className="signUpForm" onSubmit={handleSubmit}>
            <TextInput
              name="name"
              label="Nombre completo"
              placeholder="Tu nombre"
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
              name="email"
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

            <PasswordInput
              name="password"
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
              name="confirmPassword"
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

          <Text className="signUpFooterText">
            ¿Ya tienes una cuenta?{' '}
            <Anchor
              href="#login"
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

        {viewport !== 'mobile' && (
          <aside className="signUpVisualPanel" aria-hidden="true" />
        )}
      </div>
    </main>
  );
}

export default SignUp;