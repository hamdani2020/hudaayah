/// Maps the backend error envelope:
///   { "error": { "code": "...", "message": "...", "request_id": "..." } }
class ApiException implements Exception {
  final String code;
  final String message;
  final String? requestId;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.requestId,
    this.statusCode,
  });

  factory ApiException.fromEnvelope(Map<String, dynamic>? body, int? status) {
    final error = (body?['error'] as Map?)?.cast<String, dynamic>();
    return ApiException(
      code: error?['code'] as String? ?? 'unknown_error',
      message: error?['message'] as String? ?? 'Something went wrong.',
      requestId: error?['request_id'] as String?,
      statusCode: status,
    );
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
