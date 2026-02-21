import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/items/presentation/detail_screen.dart';
import '../features/items/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'shell.dart';
import 'splash_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);

  // When auth is disabled, we don't need to wait on token hydration.
  final auth = config.enableAuth ? ref.watch(authControllerProvider) : null;

  return GoRouter(
    initialLocation: config.enableAuth
        ? const SplashRoute().location
        : const HomeRoute().location,
    redirect: (context, state) {
      if (!config.enableAuth) return null;

      final a = auth!;
      final isSplash = state.matchedLocation == const SplashRoute().location;
      final isLogin = state.matchedLocation == const LoginRoute().location;

      if (a.isLoading) {
        return isSplash ? null : const SplashRoute().location;
      }

      final isAuthed = a.value?.isAuthenticated ?? false;
      if (!isAuthed) {
        return isLogin ? null : const LoginRoute().location;
      }

      // Authenticated: keep users out of login/splash.
      if (isLogin || isSplash) {
        return const HomeRoute().location;
      }

      return null;
    },
    routes: [
      if (config.enableAuth) ...[
        GoRoute(
          path: const SplashRoute().location,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: const LoginRoute().location,
          builder: (context, state) => const LoginScreen(),
        ),
      ],
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: const HomeRoute().location,
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'item/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DetailScreen(id: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: const SettingsRoute().location,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

// Small typed-route helpers (no codegen).
class SplashRoute {
  const SplashRoute();
  String get location => '/splash';
}

class LoginRoute {
  const LoginRoute();
  String get location => '/login';
}

class HomeRoute {
  const HomeRoute();
  String get location => '/home';
}

class SettingsRoute {
  const SettingsRoute();
  String get location => '/settings';
}
