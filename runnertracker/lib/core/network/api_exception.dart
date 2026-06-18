import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.originalException,
  });

  final String message;
  final int? statusCode;
  final Object? originalException;

  factory ApiException.fromDioException(DioException exception) {
    return ApiException(
      message: _resolveMessage(exception),
      statusCode: exception.response?.statusCode,
      originalException: exception,
    );
  }

  static String _resolveMessage(DioException exception) {
    final data = exception.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.badResponse:
        return 'Server returned an error response.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server.';
      case DioExceptionType.badCertificate:
        return 'Server certificate is invalid.';
      case DioExceptionType.unknown:
        return 'Unexpected network error.';
    }
  }

  @override
  String toString() {
    if (statusCode == null) {
      return 'ApiException: $message';
    }

    return 'ApiException($statusCode): $message';
  }
}
