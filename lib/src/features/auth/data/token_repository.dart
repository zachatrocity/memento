import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/secure_storage_provider.dart';

class TokenRepository {
  TokenRepository(this._store);

  static const tokenKey = 'auth_token';

  final SecureKeyValueStore _store;

  Future<String?> read() => _store.read(tokenKey);

  Future<void> write(String token) => _store.write(tokenKey, token);

  Future<void> delete() => _store.delete(tokenKey);
}

final tokenRepositoryProvider = Provider<TokenRepository>((ref) {
  return TokenRepository(ref.watch(secureStoreProvider));
});
