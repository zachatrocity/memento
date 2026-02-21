import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:swell/src/app/app.dart';
import 'package:swell/src/config/app_config.dart';
import 'package:swell/src/config/app_env.dart';
import 'package:swell/src/core/storage/secure_storage_provider.dart';
import 'package:swell/src/features/auth/data/token_repository.dart';
import 'package:swell/src/features/auth/presentation/login_screen.dart';
import 'package:swell/src/features/items/presentation/home_screen.dart';

import 'support/in_memory_store.dart';

void main() {
  AppConfig config({required bool enableAuth}) {
    return AppConfig(
      env: AppEnv.dev,
      apiBaseUrl: 'mock://',
      appName: 'Swell (Test)',
      enableNetworkLogging: false,
      useFakeBackend: true,
      enableAuth: enableAuth,
    );
  }

  testWidgets('unauthenticated: shows login when auth enabled', (tester) async {
    final store = InMemoryStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWithValue(store),
          appConfigProvider.overrideWithValue(config(enableAuth: true)),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('unauthenticated: shows home when auth disabled', (tester) async {
    final store = InMemoryStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWithValue(store),
          appConfigProvider.overrideWithValue(config(enableAuth: false)),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('token exists: shows home (auth enabled)', (tester) async {
    final store = InMemoryStore();
    await store.write(TokenRepository.tokenKey, 'test-token');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWithValue(store),
          appConfigProvider.overrideWithValue(config(enableAuth: true)),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('token exists: shows home (auth disabled)', (tester) async {
    final store = InMemoryStore();
    await store.write(TokenRepository.tokenKey, 'test-token');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWithValue(store),
          appConfigProvider.overrideWithValue(config(enableAuth: false)),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
