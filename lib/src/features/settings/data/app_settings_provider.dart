import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_CBC_PKCS7Padding,
  ),
);

const _debugModeKey = 'debug_mode_enabled';
const _clientIdKey = 'google_oauth_client_id';

/// Provider for app settings (debug mode, etc.)
final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);

class AppSettingsState {
  final bool debugModeEnabled;
  final String? clientId;

  const AppSettingsState({
    this.debugModeEnabled = false,
    this.clientId,
  });

  AppSettingsState copyWith({
    bool? debugModeEnabled,
    String? clientId,
  }) {
    return AppSettingsState(
      debugModeEnabled: debugModeEnabled ?? this.debugModeEnabled,
      clientId: clientId ?? this.clientId,
    );
  }
}

class AppSettingsNotifier extends AsyncNotifier<AppSettingsState> {
  @override
  Future<AppSettingsState> build() async {
    try {
      final debugMode = await _storage.read(key: _debugModeKey);
      final clientId = await _storage.read(key: _clientIdKey);
      
      return AppSettingsState(
        debugModeEnabled: debugMode == 'true',
        clientId: clientId,
      );
    } catch (e) {
      return const AppSettingsState();
    }
  }

  Future<void> toggleDebugMode(bool enabled) async {
    final current = state.valueOrNull ?? const AppSettingsState();
    state = AsyncValue.data(current.copyWith(debugModeEnabled: enabled));
    
    try {
      await _storage.write(key: _debugModeKey, value: enabled.toString());
    } catch (e) {
      // Ignore storage errors
    }
  }
}
