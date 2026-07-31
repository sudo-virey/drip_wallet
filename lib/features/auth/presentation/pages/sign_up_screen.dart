import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_event.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late DripFormController _controller;

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
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          // Mostrar diálogo de error más prominente
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Registration Failed'),
              content: Text(state.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.dripBackground,
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    _buildLogo(),
                    const SizedBox(height: 32),
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Join Drip Wallet and manage your family budget.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Column(
                        children: [
                          DripTextField(
                            id: 'name',
                            controller: _controller,
                            hintText: 'e.g. John Doe',
                            label: 'FULL NAME',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 24),
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
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: BlocConsumer<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return DripButton(
                                  onPressed: state is AuthLoading
                                      ? () {}
                                      : () => _handleSignUp(),
                                  label: state is AuthLoading
                                      ? 'Creating Account...'
                                      : 'Sign Up',
                                );
                              },
                              listener: (context, state) {
                                // Listener para manejar cambios de estado
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildDividerWithOr(),
                          const SizedBox(height: 10),
                          _buildGoogleSignUpButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        GestureDetector(
                          onTap: () => context.push('/login'),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Image.asset(
        'assets/images/icon_drip_wallet.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.home, size: 50),
          );
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
          child: Text(
            'OR',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: const Divider()),
      ],
    );
  }

  Widget _buildGoogleSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _handleGoogleSignUp,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _handleSignUp() {
    // 1. Validar el formulario usando el controlador de drip_ui
    if (!_controller.validateAll()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Please check all fields and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Obtener valores de los campos
    final name = _controller.getTextController('name').text.trim();
    final email = _controller.getTextController('email').text.trim();
    final password = _controller.getTextController('password').text.trim();

    // 3. Validaciones adicionales del lado del cliente
    if (name.isEmpty) {
      _showErrorDialog('Full name is required');
      return;
    }

    if (email.isEmpty) {
      _showErrorDialog('Email is required');
      return;
    }

    if (!email.contains('@')) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('Password must be at least 6 characters long');
      return;
    }

    // 4. Disparar el evento al BLoC
    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            name: name,
            email: email,
            password: password,
          ),
        );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignUp() async {
    try {
      context.read<AuthBloc>().add(AuthGoogleRequested());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign Up failed: $e')),
        );
      }
    }
  }
}
