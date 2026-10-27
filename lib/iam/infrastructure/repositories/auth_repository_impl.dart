import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../shared/domain/services/storage_service.dart';
import '../../../shared/infrastructure/network/api_exception.dart';
import '../../../shared/infrastructure/network/session_token.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _sessionKey = 'session_user';

  final Dio dio;
  final StorageService storage;
  final SessionToken token;

  AuthRepositoryImpl({required this.dio, required this.storage, required this.token});

  @override
  Future<AuthUser?> restoreSession() async {
    final raw = await storage.read(_sessionKey);
    if (raw == null) return null;
    try {
      final user = AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      token.value = user.token;
      return user;
    } catch (_) {
      await storage.delete(_sessionKey);
      return null;
    }
  }

  @override
  Future<AuthUser> signIn(String username, String password) async {
    try {
      final response = await dio.post(
        '/api/v1/authentication/sign-in',
        data: {'username': username, 'password': password},
      );
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);
      token.value = user.token;
      await storage.write(_sessionKey, jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 401:
          throw const ApiException('Usuario o contraseña incorrectos', status: 401);
        case 403:
          throw const ApiException('Verifica tu correo institucional antes de ingresar', status: 403);
      }
      throw ApiException.from(e, 'No se pudo iniciar sesión');
    }
  }

  @override
  Future<void> signOut() async {
    token.value = null;
    await storage.delete(_sessionKey);
  }
}
