import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'secure_storage.dart';

final secureStoreProvider = Provider<SecureKeyValueStore>((ref) {
  return FlutterSecureStore();
});
