// Backend desplegado en Render (el mismo que usa la app nativa del Estudiante).
class ApiConfig {
  static const baseUrl = 'https://skillswap-webservices-java.onrender.com';

  // Render (plan gratis) puede estar dormido: la primera llamada tarda
  static const timeout = Duration(seconds: 60);
}
