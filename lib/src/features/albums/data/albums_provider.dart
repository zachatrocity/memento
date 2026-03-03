import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memento/src/core/photos/google_photos_service.dart';

final albumsProvider = FutureProvider<List<GooglePhotoAlbum>>((ref) async {
  final service = ref.watch(googlePhotosServiceProvider);
  return service.getAlbums();
});

final albumPhotosProvider = FutureProvider.family<List<GooglePhotoMedia>, String>((ref, albumId) async {
  final service = ref.watch(googlePhotosServiceProvider);
  return service.getPhotos(albumId, pageSize: 200);
});

final googleAuthStateProvider = StateNotifierProvider<GoogleAuthNotifier, AsyncValue<AuthState>>((ref) {
  final service = ref.watch(googlePhotosServiceProvider);
  return GoogleAuthNotifier(service);
});

class AuthState {
  final bool isAuthenticated;
  final String? error;
  final String? email;

  const AuthState({
    this.isAuthenticated = false,
    this.error,
    this.email,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? error,
    String? email,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
      email: email ?? this.email,
    );
  }
}

class GoogleAuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final GooglePhotosService _service;

  GoogleAuthNotifier(this._service) : super(const AsyncValue.data(AuthState()));

  Future<void> checkAuth() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(AuthState(isAuthenticated: _service.isSignedIn));
  }

  Future<void> signIn() async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.signIn();
      if (result['success'] == true) {
        state = AsyncValue.data(AuthState(
          isAuthenticated: true,
          email: result['email'] as String?,
        ));
      } else {
        state = AsyncValue.data(AuthState(
          isAuthenticated: false,
          error: result['error'] as String?,
        ));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _service.signOut();
    state = const AsyncValue.data(AuthState(isAuthenticated: false));
  }
}
