import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_event.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late DripFormController _controller;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = DripFormController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      // Escucha los estados del BLoC
      listener: (context, state) {
        if (state is Authenticated) {
          // Navegar a la pantalla principal
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthError) {
          // Mostrar mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
            ), // Acceso al mensaje del BLoC[cite: 26]
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.dripBackground,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 80),
                _buildLogo(),
                const SizedBox(height: 40),

                Text('Welcome Back', style: theme.textTheme.headlineLarge),
                const SizedBox(height: 12),
                const Text(
                  'Log in to your account to manage your budget and expenses.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    children: [
                      DripTextField(
                        id: 'email',
                        controller: _controller,
                        hintText: 'example@domain.com',
                        label: 'EMAIL ADDRESS',
                        prefixIcon: Icons.email_outlined,
                        validations: [
                          DripValidation('required', customMessage: 'El email es obligatorio'),
                          DripValidation('email', customMessage: 'Ingresa un formato válido'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      DripTextField(
                        id: 'password',
                        controller: _controller,
                        hintText: '••••••••',
                        label: 'PASSWORD',
                        prefixIcon: Icons.lock_outline,
                        validations: [
                          DripValidation('required', customMessage: 'La contraseña es obligatoria'),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: // En tu DripButton, dentro de la UI
                        BlocConsumer<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return DripButton(
                              onPressed: state is AuthLoading
                                  ? () {}
                                  : () => _handleLogin(),
                              label: state is AuthLoading
                                  ? 'Logging in...'
                                  : 'Log In',
                            );
                          },
                          listener: (context, state) {
                            // ... lógica del listener anterior ...
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDividerWithOr(),
                      const SizedBox(height: 10),
                      _buildGoogleSignInButton(),
                    ],
                  ),
                ),

                // Footer fuera de la tarjeta
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have a family account? '),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/signup'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      child: Image.asset(
        'assets/images/icon_drip_wallet.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.home, size: 50));
        },
      ),
    );
  }

  Widget _buildDividerWithOr() {
    return Row(
      children: [
        Expanded(child: const Divider()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('OR', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: const Divider()),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _handleGoogleSignIn,
        icon: Image.asset(
          'assets/images/google_logo.png',
          width: 20,
          height: 20,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.account_circle);
          },
        ),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // En tu LoginScreen
  Future<void> _handleLogin() async {
    // 1. Validar el formulario usando el controlador de drip_ui
    if (!_controller.validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, revisa tus datos')),
      );
      return;
    }

    // Disparar el evento al BLoC
    context.read<AuthBloc>().add(
      AuthSignInRequested(
        email: _controller.getTextController('email').text,
        password: _controller.getTextController('password').text,
      ), // Usamos el evento correcto[cite: 25]
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      // TODO: Implement Google Sign In logic
      print('Google Sign In tapped');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google Sign In failed: $e')));
      }
    }
  }
}
