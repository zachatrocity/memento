import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class DioLoggerInterceptor extends Interceptor {
  DioLoggerInterceptor({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i('→ ${options.method} ${options.baseUrl}${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i(
      '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _logger.w(
      '✕ ${status ?? '-'} ${err.requestOptions.method} ${err.requestOptions.path}: ${err.message}',
    );
    handler.next(err);
  }
}
