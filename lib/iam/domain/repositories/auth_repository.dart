import '../models/auth_user.dart';

abstract class AuthRepository {
  // Sesión guardada en el teléfono, o null si no hay.
  Future<AuthUser?> restoreSession();

  // 200 AuthUser | 401 credenciales inválidas | 403 correo sin verificar
  Future<AuthUser> signIn(String username, String password);

  Future<void> signOut();
}
