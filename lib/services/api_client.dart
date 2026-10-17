import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// Error de red o del backend con un mensaje listo para mostrar.
class ApiException implements Exception {
  final int? status;
  final String message;

  const ApiException(this.message, {this.status});

  @override
  String toString() => message;
}

// Cliente REST único: URL base, token JWT y manejo de errores (ProblemDetail del backend).
class ApiClient {
  static const baseUrl = 'https://skillswap-webservices-java.onrender.com';

  // Render (plan gratis) puede estar dormido: la primera llamada tarda
  static const _timeout = Duration(seconds: 60);

  String? token;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<http.Response> get(String path, {Map<String, String>? query}) {
    return _send(() => http.get(_uri(path, query), headers: _headers));
  }

  Future<http.Response> post(String path, {Object? body}) {
    return _send(() => http.post(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)));
  }

  Future<http.Response> patch(String path, {Object? body}) {
    return _send(() => http.patch(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)));
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder');
    } on SocketException {
      throw const ApiException('No se pudo conectar con el servidor');
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con el servidor');
    }
  }

  // Texto del error del backend (ProblemDetail.detail o title) o uno por defecto.
  static String errorFrom(http.Response response, String fallback) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) {
        final detail = data['detail'] ?? data['title'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } catch (_) {}
    return fallback;
  }

  static dynamic decode(http.Response response) => jsonDecode(utf8.decode(response.bodyBytes));
}
