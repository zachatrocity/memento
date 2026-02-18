import 'package:swell/src/core/storage/secure_storage.dart';

class InMemoryStore implements SecureKeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }
}
