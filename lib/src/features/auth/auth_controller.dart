import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_providers.dart';
import 'auth_state.dart';
import 'data/auth_api.dart';
import 'data/auth_repository.dart';
import 'data/token_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final tokens = ref.watch(tokenRepositoryProvider);
    final existing = await tokens.read();

    if (existing != null && existing.isNotEmpty) {
      return AuthState.authenticated(existing);
    }

    return AuthState.unauthenticated();
  }

  AuthRepository _repo() {
    final dio = ref.read(dioProvider);
    final tokens = ref.read(tokenRepositoryProvider);

    return AuthRepository(api: DioAuthApi(dio), tokens: tokens);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final token = await _repo().login(email: email, password: password);
      return AuthState.authenticated(token);
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo().logout();
      return AuthState.unauthenticated();
    });
  }
}
