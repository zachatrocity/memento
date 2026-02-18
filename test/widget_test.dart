import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:swell/src/app/app.dart';
import 'package:swell/src/core/storage/secure_storage_provider.dart';
import 'package:swell/src/features/auth/data/token_repository.dart';
import 'package:swell/src/features/auth/presentation/login_screen.dart';
import 'package:swell/src/features/items/presentation/home_screen.dart';

import 'support/in_memory_store.dart';

void main() {
  testWidgets('shows login when unauthenticated', (tester) async {
    final store = InMemoryStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(store)],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('shows home when token exists', (tester) async {
    final store = InMemoryStore();
    await store.write(TokenRepository.tokenKey, 'test-token');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(store)],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
