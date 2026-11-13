part of 'supervision_bloc.dart';

sealed class SupervisionEvent {
  const SupervisionEvent();
}

// Carga la lista de Verificadores; con [silent] la refresca sin mostrar el indicador de carga.
class SupervisionRequested extends SupervisionEvent {
  final bool silent;

  const SupervisionRequested({this.silent = false});
}

class VerifierSuspended extends SupervisionEvent {
  final int verifierUserId;
  final String justification;

  const VerifierSuspended(this.verifierUserId, this.justification);
}

class VerifierReinstated extends SupervisionEvent {
  final int verifierUserId;

  const VerifierReinstated(this.verifierUserId);
}
