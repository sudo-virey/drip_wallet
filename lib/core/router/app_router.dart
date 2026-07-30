import 'package:drip_wallet/core/router/go_router_refresh_stream.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/ui/layout/main_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:drip_wallet/features/auth/presentation/pages/login_screen.dart';
import 'package:drip_wallet/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:drip_wallet/features/home/presentation/pages/home_screen.dart';
import 'package:drip_wallet/features/history/presentation/pages/history_screen.dart';
import 'package:drip_wallet/features/profile/presentation/pages/profile_screen.dart';


// En app_router.dart
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/home',
    // Esto hace que el router se actualice cuando cambia el estado del BLoC
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSignUp = state.matchedLocation == '/signup';
      if (authState is AuthInitial || authState is AuthLoading) {
        return null; // O podrías retornar '/splash' si tuvieras una ruta así
      }
      if (authState is Unauthenticated && !isGoingToLogin && !isGoingToSignUp) {
        return '/login';
      }
      if (authState is Authenticated && (isGoingToLogin || isGoingToSignUp)) {
        return '/home';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainLayout(navigationShell: navigationShell), //
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/history', builder: (context, state) => const HistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    ],
  );
}