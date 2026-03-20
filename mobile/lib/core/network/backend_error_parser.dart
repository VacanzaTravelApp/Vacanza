import 'package:dio/dio.dart';

class BackendError {
  final int? status;
  final String? error;
  final String message;
  final String? path;

  const BackendError({
    required this.message,
    this.status,
    this.error,
    this.path,
  });

  factory BackendError.fromDioException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final path = e.requestOptions.path;

    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      final err = data['error'];
      final timestamp = data['timestamp'];
      final backendPath = data['path']?.toString() ?? path;

      if (msg is String && msg.trim().isNotEmpty) {
        return BackendError(
          status: status,
          error: err is String ? err : null,
          message: msg.trim(),
          path: backendPath,
        );
      }

      // Fallback: try \"error\" if message missing.
      if (err is String && err.trim().isNotEmpty) {
        return BackendError(
          status: status,
          error: err.trim(),
          message: err.trim(),
          path: backendPath,
        );
      }

      if (timestamp != null) {
        return BackendError(
          status: status,
          error: err is String ? err : null,
          message: 'Request failed (status: $status) at $backendPath',
          path: backendPath,
        );
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return BackendError(
        status: status,
        message: data.trim(),
        path: path,
      );
    }

    if (status != null) {
      return BackendError(
        status: status,
        message: 'Request failed (status: $status) at $path',
        path: path,
      );
    }

    return BackendError(
      status: status,
      message: e.message ?? 'Request failed',
      path: path,
    );
  }
}

String extractBackendMessage(DioException e) {
  return BackendError.fromDioException(e).message;
}

