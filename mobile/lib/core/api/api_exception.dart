class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fields = const {},
    this.retryAfter,
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, String> fields;
  final int? retryAfter;

  String get displayMessage {
    if (fields.isEmpty) {
      return message;
    }
    return fields.values.join('\n');
  }

  @override
  String toString() => displayMessage;
}
