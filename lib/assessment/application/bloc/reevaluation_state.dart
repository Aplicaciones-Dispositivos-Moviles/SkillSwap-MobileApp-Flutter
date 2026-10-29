part of 'reevaluation_bloc.dart';

sealed class ReevaluationState {
  const ReevaluationState();
}

class ReevaluationLoading extends ReevaluationState {
  const ReevaluationLoading();
}

// 403: quien consulta no es Verificador senior
class ReevaluationForbidden extends ReevaluationState {
  const ReevaluationForbidden();
}

class ReevaluationError extends ReevaluationState {
  final String message;

  const ReevaluationError(this.message);
}

class ReevaluationLoaded extends ReevaluationState {
  final List<ReevaluationCandidate> candidates;
  final String? busyKey; // resultado cuya reevaluación se está ordenando
  final String? notice; // confirmación para mostrar una sola vez
  final String? error; // error para mostrar una sola vez

  const ReevaluationLoaded(this.candidates, {this.busyKey, this.notice, this.error});

  // Copia con otra lista o estado de envío; lo que no se indica vuelve a su valor inicial.
  ReevaluationLoaded copyWith({
    List<ReevaluationCandidate>? candidates,
    String? busyKey,
    String? notice,
    String? error,
  }) =>
      ReevaluationLoaded(candidates ?? this.candidates, busyKey: busyKey, notice: notice, error: error);
}
