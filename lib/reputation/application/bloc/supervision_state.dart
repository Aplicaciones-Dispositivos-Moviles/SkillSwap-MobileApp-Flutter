part of 'supervision_bloc.dart';

sealed class SupervisionState {
  const SupervisionState();
}

class SupervisionLoading extends SupervisionState {
  const SupervisionLoading();
}

// 403: quien consulta no es Verificador senior
class SupervisionForbidden extends SupervisionState {
  const SupervisionForbidden();
}

class SupervisionError extends SupervisionState {
  final String message;

  const SupervisionError(this.message);
}

class SupervisionLoaded extends SupervisionState {
  final List<VerifierMetric> verifiers;
  final int? busyUserId; // Verificador cuya suspensión o reactivación se está guardando
  final String? notice; // confirmación para mostrar una sola vez
  final String? error; // error para mostrar una sola vez

  const SupervisionLoaded(this.verifiers, {this.busyUserId, this.notice, this.error});

  // Copia con otra lista o estado de guardado; lo que no se indica vuelve a su valor inicial.
  SupervisionLoaded copyWith({List<VerifierMetric>? verifiers, int? busyUserId, String? notice, String? error}) =>
      SupervisionLoaded(verifiers ?? this.verifiers, busyUserId: busyUserId, notice: notice, error: error);
}
