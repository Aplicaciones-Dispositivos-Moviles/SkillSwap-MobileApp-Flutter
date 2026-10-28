part of 'cases_bloc.dart';

sealed class CasesState {
  const CasesState();
}

class CasesInitial extends CasesState {
  const CasesInitial();
}

class CasesLoading extends CasesState {
  const CasesLoading();
}

// Quien inició sesión todavía no tiene perfil de Verificador
class NotAVerifier extends CasesState {
  const NotAVerifier();
}

class CasesLoaded extends CasesState {
  final VerifierProfile profile;
  final List<VerificationCase> cases;
  final VerifierReliability? reliability;
  final int? balance;

  const CasesLoaded({required this.profile, required this.cases, this.reliability, this.balance});

  List<VerificationCase> get pending => cases.where((c) => !c.isResolved).toList();
  bool get isSenior => reliability?.seniorVerifier ?? false;
}

class CasesError extends CasesState {
  final String message;

  const CasesError(this.message);
}
