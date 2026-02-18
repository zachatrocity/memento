import 'package:dio/dio.dart';

import 'app_exception.dart';

AppException mapDioException(DioException e) {
  // Keep it simple: map to a small set of user-friendly messages.
  final type = e.type;

  if (type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.receiveTimeout) {
    return AppException(
      'Request timed out',
      userMessage: 'Network timeout. Please try again.',
      cause: e,
      stackTrace: e.stackTrace,
    );
  }

  if (type == DioExceptionType.connectionError) {
    return AppException(
      'Connection error',
      userMessage: 'Unable to connect. Check your network and try again.',
      cause: e,
      stackTrace: e.stackTrace,
    );
  }

  final status = e.response?.statusCode;
  if (status == 401) {
    return AppException(
      'Unauthorized',
      userMessage: 'Your session expired. Please sign in again.',
      cause: e,
      stackTrace: e.stackTrace,
    );
  }

  if (status != null && status >= 500) {
    return AppException(
      'Server error: $status',
      userMessage: 'Server error. Please try again later.',
      cause: e,
      stackTrace: e.stackTrace,
    );
  }

  return AppException(
    'Request failed',
    userMessage: 'Something went wrong. Please try again.',
    cause: e,
    stackTrace: e.stackTrace,
  );
}
