import 'package:drip_wallet/core/theme/app_theme.dart';
import 'package:drip_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await setup();
  runApp(const DripWalletApp());
}

class DripWalletApp extends StatelessWidget {
  const DripWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AuthBloc(getIt<AuthRepository>())..add(AuthCheckRequested()),
      // 1. Especifica los tipos <AuthBloc, AuthState>
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print("ESTADO DEL BLOC: $state");
        },
        child: Builder(
          builder: (newContext) {
            // 2. Usa este 'newContext'
            // 3. Usa 'newContext' para leer el Bloc, NO 'context'
            final authBloc = newContext.read<AuthBloc>();

            return MaterialApp.router(
              title: 'Drip Wallet',
              routerConfig: createRouter(authBloc),
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode
                  .system, // Cambia automáticamente según el dispositivo
            );
          },
        ),
      ),
    );
  }
}
