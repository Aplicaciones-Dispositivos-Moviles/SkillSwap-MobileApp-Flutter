part of 'supervision_bloc.dart';

sealed class SupervisionEvent {
  const SupervisionEvent();
}

// Carga (o recarga) la lista de Verificadores.
class SupervisionRequested extends SupervisionEvent {
  const SupervisionRequested();
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
