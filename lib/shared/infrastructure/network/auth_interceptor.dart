import 'package:dio/dio.dart';

import 'session_token.dart';

// Agrega el token a cada request y avisa cuando el backend lo rechaza por vencido (401).
class AuthInterceptor extends Interceptor {
  final SessionToken token;

  AuthInterceptor(this.token);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final value = token.value;
    if (value != null) options.headers['Authorization'] = 'Bearer $value';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isSignIn = err.requestOptions.path.contains('/authentication/');
    if (err.response?.statusCode == 401 && token.value != null && !isSignIn) {
      token.onExpired?.call();
    }
    handler.next(err);
  }
}
