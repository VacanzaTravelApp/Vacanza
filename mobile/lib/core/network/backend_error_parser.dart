import 'package:dio/dio.dart';

class BackendError {
  final int? status;
  final String? error;
  final String message;

  const BackendError({
    required this.message,
    this.status,
    this.error,
  });

  factory BackendError.fromDioException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // Connectivity / timeout errors — never show Dio internals
    if (_isConnectivityError(e)) {
      return const BackendError(
        message: 'No internet connection. Please check your connection and try again.',
      );
    }
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const BackendError(
        message: 'The request timed out. Please try again.',
      );
    }

    // Try to extract message from backend response body
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      final err = data['error'];

      if (msg is String && msg.trim().isNotEmpty) {
        return BackendError(
          status: status,
          error: err is String ? err : null,
          message: msg.trim(),
        );
      }
      if (err is String && err.trim().isNotEmpty) {
        return BackendError(
          status: status,
          error: err.trim(),
          message: err.trim(),
        );
      }
    }

    if (data is String && data.trim().isNotEmpty && data.length < 200) {
      return BackendError(status: status, message: data.trim());
    }

    // Map HTTP status codes to user-friendly messages
    if (status != null) {
      return BackendError(status: status, message: _statusMessage(status));
    }

    return const BackendError(message: 'Something went wrong. Please try again.');
  }
}

bool _isConnectivityError(DioException e) =>
    e.type == DioExceptionType.connectionError ||
    e.type == DioExceptionType.connectionTimeout;

String _statusMessage(int status) {
  switch (status) {
    case 400:
      return 'Invalid request. Please check your input and try again.';
    case 401:
      return 'Your session has expired. Please sign in again.';
    case 403:
      return 'You do not have permission to do that.';
    case 404:
      return 'The requested resource was not found.';
    case 409:
      return 'A conflict occurred. Please try again.';
    case 422:
      return 'The submitted data is invalid. Please check and try again.';
    case 429:
      return 'Too many requests. Please wait a moment and try again.';
    case 500:
    case 502:
    case 503:
    case 504:
      return 'Something went wrong on our end. Please try again later.';
    default:
      if (status >= 500) {
        return 'Server error. Please try again later.';
      }
      return 'Something went wrong. Please try again.';
  }
}

/// Returns a user-friendly message for a [DioException].
/// Connectivity errors, timeouts, status codes, and backend messages
/// are all mapped — no raw Dart exception text is ever returned.
String extractBackendMessage(DioException e) =>
    BackendError.fromDioException(e).message;
