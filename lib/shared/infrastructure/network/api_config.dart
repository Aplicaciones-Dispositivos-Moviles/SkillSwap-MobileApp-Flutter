// Backend desplegado en AWS (el mismo que usa la app nativa del Estudiante).
class ApiConfig {
  static const baseUrl = 'https://skillswap-innovify.duckdns.org';

  // La generación y evaluación con IA del backend puede tardar varios segundos
  static const timeout = Duration(seconds: 60);
}
