// Token JWT de la sesión actual, compartido entre el repositorio de autenticación y el interceptor.
// onExpired lo llama el interceptor cuando el backend responde 401: la app vuelve al login.
class SessionToken {
  String? value;
  void Function()? onExpired;
}
