part of 'cases_bloc.dart';

sealed class CasesEvent {
  const CasesEvent();
}

// Carga (o recarga) el inicio del Verificador.
class CasesRequested extends CasesEvent {
  const CasesRequested();
}

// El Verificador activa o pausa la recepción de casos nuevos (T72).
class AvailabilityChanged extends CasesEvent {
  final bool available;

  const AvailabilityChanged(this.available);
}
