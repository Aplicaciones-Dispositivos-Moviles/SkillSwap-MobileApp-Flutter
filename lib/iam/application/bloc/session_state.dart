part of 'session_bloc.dart';

sealed class SessionState {
  const SessionState();
}

// Todavía se está leyendo la sesión guardada.
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class Unauthenticated extends SessionState {
  final String? message;

  const Unauthenticated({this.message});
}

class Authenticating extends SessionState {
  const Authenticating();
}

class Authenticated extends SessionState {
  final AuthUser user;

  const Authenticated(this.user);
}
