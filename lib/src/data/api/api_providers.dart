import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../core/logging/logger_provider.dart';
import '../../features/auth/data/token_repository.dart';
import '../fake_backend/fake_backend_interceptor.dart';
import 'auth_header_interceptor.dart';
import 'dio_logger_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final logger = ref.watch(loggerProvider);
  final tokens = ref.watch(tokenRepositoryProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(AuthHeaderInterceptor(tokens));

  if (config.useFakeBackend) {
    dio.interceptors.add(FakeBackendInterceptor(logger: logger));
  }

  if (config.enableNetworkLogging) {
    dio.interceptors.add(DioLoggerInterceptor(logger: logger));
  }

  return dio;
});
