// AuthenticatedUserResource del backend (respuesta de sign-in) más el nombre completo de GET /api/v1/users/me
class AuthUser {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool isVerified;
  final String token;
  final String? fullName; // null si no se pudo leer el perfil

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.token,
    this.fullName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      isVerified: (json['isVerified'] ?? false) as bool,
      token: json['token'] as String,
      fullName: json['fullName'] as String?,
    );
  }

  AuthUser withFullName(String? name) => AuthUser(
        id: id, username: username, email: email, role: role, isVerified: isVerified, token: token, fullName: name);

  // Nombre para el saludo: el primer nombre si hay nombre completo; si no, el usuario.
  String get greetingName {
    final first = fullName?.trim().split(RegExp(r'\s+')).first ?? '';
    return first.isEmpty ? username : first;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'role': role,
        'isVerified': isVerified,
        'token': token,
        if (fullName != null) 'fullName': fullName,
      };
}
