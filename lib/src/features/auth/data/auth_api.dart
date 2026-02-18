import 'package:dio/dio.dart';

import '../../../core/errors/dio_exception_mapper.dart';
import '../../../core/errors/app_exception.dart';

abstract class AuthApi {
  Future<String> login({required String email, required String password});
}

class DioAuthApi implements AuthApi {
  DioAuthApi(this._dio);

  final Dio _dio;

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = res.data?['token'];
      if (token is String && token.isNotEmpty) return token;

      throw const AppException('Login response missing token');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
