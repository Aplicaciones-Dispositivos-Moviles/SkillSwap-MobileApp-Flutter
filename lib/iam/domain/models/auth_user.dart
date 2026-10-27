// AuthenticatedUserResource del backend (respuesta de sign-in)
class AuthUser {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool isVerified;
  final String token;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      isVerified: (json['isVerified'] ?? false) as bool,
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'role': role,
        'isVerified': isVerified,
        'token': token,
      };
}
