import '../models/auth_user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient api;

  AuthService(this.api);

  // 200 AuthUser | 401 credenciales inválidas | 403 correo sin verificar
  Future<AuthUser> signIn(String username, String password) async {
    final response = await api.post(
      '/api/v1/authentication/sign-in',
      body: {'username': username, 'password': password},
    );
    if (response.statusCode == 200) {
      return AuthUser.fromJson(ApiClient.decode(response) as Map<String, dynamic>);
    }
    switch (response.statusCode) {
      case 401:
        throw const ApiException('Usuario o contraseña incorrectos', status: 401);
      case 403:
        throw const ApiException('Verifica tu correo institucional antes de ingresar', status: 403);
      default:
        throw ApiException(
          ApiClient.errorFrom(response, 'No se pudo iniciar sesión (${response.statusCode})'),
          status: response.statusCode,
        );
    }
  }
}
