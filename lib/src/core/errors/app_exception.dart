class AppException implements Exception {
  const AppException(
    this.message, {
    this.userMessage,
    this.cause,
    this.stackTrace,
  });

  /// Developer-facing message.
  final String message;

  /// Optional user-facing message.
  final String? userMessage;

  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException(message: $message, cause: $cause)';
}
