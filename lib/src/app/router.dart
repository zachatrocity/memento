import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/albums/presentation/albums_screen.dart';
import '../features/albums/presentation/album_detail_screen.dart';
import '../features/slideshow/presentation/create_slideshow_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'shell.dart';
import 'splash_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: const SplashRoute().location,
    routes: [
      GoRoute(
        path: const SplashRoute().location,
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: const HomeRoute().location,
            builder: (context, state) => const AlbumsScreen(),
          ),
          GoRoute(
            path: '/album/:id',
            builder: (context, state) {
              final albumId = state.pathParameters['id']!;
              return AlbumDetailScreen(albumId: albumId);
            },
          ),
          GoRoute(
            path: '/create',
            builder: (context, state) {
              final selectedIds = state.extra as List<String>? ?? [];
              return CreateSlideshowScreen(selectedPhotoIds: selectedIds);
            },
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

// Typed routes
class SplashRoute {
  const SplashRoute();
  String get location => '/splash';
}

class HomeRoute {
  const HomeRoute();
  String get location => '/home';
}

class SettingsRoute {
  const SettingsRoute();
  String get location => '/settings';
}
