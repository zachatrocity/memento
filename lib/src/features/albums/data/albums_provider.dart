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

final googleAuthStateProvider = StateNotifierProvider<GoogleAuthNotifier, AsyncValue<bool>>((ref) {
  final service = ref.watch(googlePhotosServiceProvider);
  return GoogleAuthNotifier(service);
});

class GoogleAuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final GooglePhotosService _service;

  GoogleAuthNotifier(this._service) : super(const AsyncValue.data(false));

  Future<void> checkAuth() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(_service.isSignedIn);
  }

  Future<void> signIn() async {
    state = const AsyncValue.loading();
    try {
      final success = await _service.signIn();
      state = AsyncValue.data(success);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _service.signOut();
    state = const AsyncValue.data(false);
  }
}
