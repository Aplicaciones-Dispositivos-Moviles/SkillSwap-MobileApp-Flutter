part of 'cases_bloc.dart';

sealed class CasesEvent {
  const CasesEvent();
}

// Carga (o recarga) el inicio del Verificador.
class CasesRequested extends CasesEvent {
  const CasesRequested();
}
