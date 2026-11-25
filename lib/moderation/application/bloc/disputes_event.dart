part of 'disputes_bloc.dart';

sealed class DisputesEvent {
  const DisputesEvent();
}

// Carga la lista; [resolved] pide las ya resueltas en lugar de las pendientes.
class DisputesRequested extends DisputesEvent {
  final bool resolved;

  const DisputesRequested({this.resolved = false});
}
