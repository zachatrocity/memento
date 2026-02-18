import 'package:dio/dio.dart';

import '../../features/auth/data/token_repository.dart';

class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor(this._tokens);

  final TokenRepository _tokens;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Don't attach auth to login.
    if (options.path == '/auth/login') {
      handler.next(options);
      return;
    }

    final token = await _tokens.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}
