import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/items/presentation/detail_screen.dart';
import '../features/items/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'shell.dart';
import 'splash_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: const SplashRoute().location,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == const SplashRoute().location;
      final isLogin = state.matchedLocation == const LoginRoute().location;

      if (auth.isLoading) {
        return isSplash ? null : const SplashRoute().location;
      }

      final isAuthed = auth.value?.isAuthenticated ?? false;
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
      GoRoute(
        path: const SplashRoute().location,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: const LoginRoute().location,
        builder: (context, state) => const LoginScreen(),
      ),
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
