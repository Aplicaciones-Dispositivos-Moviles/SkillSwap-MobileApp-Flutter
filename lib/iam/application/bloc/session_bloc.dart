import 'package:bloc/bloc.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'session_event.dart';
part 'session_state.dart';

// Sesión del Verificador: login, sesión guardada y cierre (manual o por token vencido).
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final AuthRepository authRepository;

  SessionBloc({required this.authRepository}) : super(const SessionUnknown()) {
    on<SessionRestoreRequested>(_onRestore);
    on<SignInRequested>(_onSignIn);
    on<SignOutRequested>(_onSignOut);
    on<SessionExpired>(_onExpired);
  }

  Future<void> _onRestore(SessionRestoreRequested event, Emitter<SessionState> emit) async {
    final user = await authRepository.restoreSession();
    emit(user == null ? const Unauthenticated() : Authenticated(user));
  }

  Future<void> _onSignIn(SignInRequested event, Emitter<SessionState> emit) async {
    if (event.username.trim().isEmpty || event.password.isEmpty) {
      emit(const Unauthenticated(message: 'Ingrese usuario y contraseña'));
      return;
    }
    emit(const Authenticating());
    try {
      final user = await authRepository.signIn(event.username.trim(), event.password);
      emit(Authenticated(user));
    } catch (e) {
      emit(Unauthenticated(message: ApiException.from(e, 'No se pudo iniciar sesión').message));
    }
  }

  Future<void> _onSignOut(SignOutRequested event, Emitter<SessionState> emit) async {
    await authRepository.signOut();
    emit(const Unauthenticated());
  }

  Future<void> _onExpired(SessionExpired event, Emitter<SessionState> emit) async {
    if (state is! Authenticated) return;
    await authRepository.signOut();
    emit(const Unauthenticated(message: 'Tu sesión venció. Inicia sesión de nuevo'));
  }
}
