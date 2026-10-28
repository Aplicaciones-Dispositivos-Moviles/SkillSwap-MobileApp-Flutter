part of 'session_bloc.dart';

sealed class SessionEvent {
  const SessionEvent();
}

// Al abrir la app: recupera la sesión guardada.
class SessionRestoreRequested extends SessionEvent {
  const SessionRestoreRequested();
}

class SignInRequested extends SessionEvent {
  final String username;
  final String password;

  const SignInRequested(this.username, this.password);
}

class SignOutRequested extends SessionEvent {
  const SignOutRequested();
}

// El backend rechazó el token (401): se vuelve al login con un aviso.
class SessionExpired extends SessionEvent {
  const SessionExpired();
}
