part of 'reevaluation_bloc.dart';

sealed class ReevaluationEvent {
  const ReevaluationEvent();
}

// Carga la lista; con [silent] la refresca sin mostrar el indicador de carga.
class ReevaluationsRequested extends ReevaluationEvent {
  final bool silent;

  const ReevaluationsRequested({this.silent = false});
}

class ReevaluationOrdered extends ReevaluationEvent {
  final ReevaluationCandidate candidate;
  final String justification;

  const ReevaluationOrdered(this.candidate, this.justification);
}
