class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.retryAfter,
  });

  final int statusCode;
  final String code;
  final String message;
  final int? retryAfter;

  @override
  String toString() => message;
}
