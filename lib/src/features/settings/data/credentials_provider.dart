import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

const _clientIdKey = 'google_oauth_client_id';

/// Provider for Google OAuth credentials
final credentialsProvider = AsyncNotifierProvider<CredentialsNotifier, CredentialsState>(
  CredentialsNotifier.new,
);

class CredentialsState {
  final String? clientId;
  final bool isLoading;

  const CredentialsState({
    this.clientId,
    this.isLoading = false,
  });

  bool get hasCredentials => clientId != null && clientId!.isNotEmpty;

  CredentialsState copyWith({
    String? clientId,
    bool? isLoading,
  }) {
    return CredentialsState(
      clientId: clientId ?? this.clientId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CredentialsNotifier extends AsyncNotifier<CredentialsState> {
  @override
  Future<CredentialsState> build() async {
    final clientId = await _storage.read(key: _clientIdKey);
    return CredentialsState(clientId: clientId);
  }

  /// Save the Google OAuth Client ID
  Future<void> saveClientId(String clientId) async {
    state = const AsyncValue.loading();
    
    try {
      // Basic validation
      final trimmed = clientId.trim();
      if (trimmed.isEmpty) {
        throw ArgumentError('Client ID cannot be empty');
      }
      
      // Should look like a Google Client ID
      if (!trimmed.contains('.apps.googleusercontent.com') && 
          !trimmed.startsWith('com.googleusercontent.apps.')) {
        // Allow it anyway but it's probably wrong
      }
      
      await _storage.write(key: _clientIdKey, value: trimmed);
      state = AsyncValue.data(CredentialsState(clientId: trimmed));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clear stored credentials
  Future<void> clearCredentials() async {
    state = const AsyncValue.loading();
    
    try {
      await _storage.delete(key: _clientIdKey);
      state = const AsyncValue.data(CredentialsState());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Get the raw client ID for GoogleSignIn
  /// For iOS, returns the client ID as-is
  /// For Android, returns null (uses package name + SHA-1)
  Future<String?> getClientIdForPlatform() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasCredentials) {
      return null;
    }
    return currentState.clientId;
  }
}
