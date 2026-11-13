import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap_verifier/iam/infrastructure/repositories/auth_repository_impl.dart';
import 'package:skillswap_verifier/shared/domain/services/storage_service.dart';
import 'package:skillswap_verifier/shared/infrastructure/network/session_token.dart';

class MemoryStorage implements StorageService {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

// Answers sign-in and, when [profileStatus] is 200, GET /api/v1/users/me with the full name.
class AuthAdapter implements HttpClientAdapter {
  AuthAdapter({this.profileStatus = 200});

  final int profileStatus;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    paths.add(options.path);
    final json = {Headers.contentTypeHeader: [Headers.jsonContentType]};
    if (options.path == '/api/v1/authentication/sign-in') {
      return ResponseBody.fromString(
        jsonEncode({'id': 2, 'username': 'verificador.prueba', 'email': 'v@upc.edu.pe', 'role': 'Student',
            'isVerified': true, 'token': 'jwt'}),
        200,
        headers: json,
      );
    }
    if (profileStatus != 200) return ResponseBody.fromString('{}', profileStatus, headers: json);
    return ResponseBody.fromString(jsonEncode({'id': 2, 'fullName': 'Verificador Prueba'}), 200, headers: json);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  AuthRepositoryImpl repositoryWith(AuthAdapter adapter, MemoryStorage storage) => AuthRepositoryImpl(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter,
        storage: storage,
        token: SessionToken(),
      );

  test('al iniciar sesión lee el nombre completo y lo guarda con la sesión', () async {
    final adapter = AuthAdapter();
    final storage = MemoryStorage();

    final user = await repositoryWith(adapter, storage).signIn('verificador.prueba', 'x');

    expect(adapter.paths, ['/api/v1/authentication/sign-in', '/api/v1/users/me']);
    expect(user.fullName, 'Verificador Prueba');
    expect(user.greetingName, 'Verificador');
    final restored = await repositoryWith(AuthAdapter(), storage).restoreSession();
    expect(restored!.greetingName, 'Verificador');
  });

  test('si el perfil no responde, la sesión se abre igual y saluda con el usuario', () async {
    final user = await repositoryWith(AuthAdapter(profileStatus: 500), MemoryStorage()).signIn('verificador.prueba', 'x');

    expect(user.fullName, isNull);
    expect(user.token, 'jwt');
    expect(user.greetingName, 'verificador.prueba');
  });
}
