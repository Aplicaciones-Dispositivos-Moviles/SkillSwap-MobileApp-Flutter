part of 'disputes_bloc.dart';

sealed class DisputesState {
  const DisputesState();
}

class DisputesLoading extends DisputesState {
  const DisputesLoading();
}

// 403: quien consulta no es un Verificador habilitado
class DisputesForbidden extends DisputesState {
  const DisputesForbidden();
}

class DisputesError extends DisputesState {
  final String message;

  const DisputesError(this.message);
}

class DisputesLoaded extends DisputesState {
  final List<Dispute> disputes;
  final bool resolved; // la lista es de las resueltas, no de las pendientes

  const DisputesLoaded(this.disputes, {this.resolved = false});
}
