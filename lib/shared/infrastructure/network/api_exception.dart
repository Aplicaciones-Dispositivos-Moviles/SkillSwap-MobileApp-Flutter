import 'package:dio/dio.dart';

// Error de red o del backend con un mensaje listo para mostrar.
class ApiException implements Exception {
  final int? status;
  final String message;

  const ApiException(this.message, {this.status});

  // Texto del ProblemDetail del backend (detail o title) o el mensaje por defecto.
  factory ApiException.fromResponse(int? status, dynamic data, String fallback) {
    if (data is Map) {
      final detail = data['detail'] ?? data['title'];
      if (detail is String && detail.isNotEmpty) return ApiException(detail, status: status);
    }
    return ApiException(fallback, status: status);
  }

  // Convierte cualquier error de Dio en un mensaje para el Verificador.
  factory ApiException.from(Object error, String fallback) {
    if (error is ApiException) return error;
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ApiException('El servidor tardó demasiado en responder');
        case DioExceptionType.connectionError:
          return const ApiException('No se pudo conectar con el servidor');
        default:
          final response = error.response;
          if (response != null) {
            return ApiException.fromResponse(response.statusCode, response.data, '$fallback (${response.statusCode})');
          }
      }
    }
    return ApiException(fallback);
  }

  @override
  String toString() => message;
}
