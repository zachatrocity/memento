import 'auth_api.dart';
import 'token_repository.dart';

class AuthRepository {
  AuthRepository({required this.api, required this.tokens});

  final AuthApi api;
  final TokenRepository tokens;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final token = await api.login(email: email, password: password);
    await tokens.write(token);
    return token;
  }

  Future<void> logout() => tokens.delete();
}
