import 'package:bloc/bloc.dart';

import '../../../recognition/domain/repositories/recognition_repository.dart';
import '../../../reputation/domain/models/verifier_reliability.dart';
import '../../../reputation/domain/repositories/reputation_repository.dart';
import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/verification_case.dart';
import '../../domain/models/verifier_profile.dart';
import '../../domain/repositories/verification_case_repository.dart';

part 'cases_event.dart';
part 'cases_state.dart';

// T71 · Inicio del Verificador (mock-up 13): perfil, saldo, confiabilidad y casos asignados.
class CasesBloc extends Bloc<CasesEvent, CasesState> {
  final int userId;
  final VerificationCaseRepository caseRepository;
  final ReputationRepository reputationRepository;
  final RecognitionRepository recognitionRepository;

  CasesBloc({
    required this.userId,
    required this.caseRepository,
    required this.reputationRepository,
    required this.recognitionRepository,
  }) : super(const CasesInitial()) {
    on<CasesRequested>(_onRequested);
  }

  Future<void> _onRequested(CasesRequested event, Emitter<CasesState> emit) async {
    if (state is! CasesLoaded) emit(const CasesLoading());
    try {
      final profile = await caseRepository.getMyProfile();
      if (profile == null) {
        emit(const NotAVerifier());
        return;
      }
      final cases = await caseRepository.getAssignedCases();
      // La confiabilidad y el saldo son opcionales: si fallan, el inicio igual se muestra
      VerifierReliability? reliability;
      int? balance;
      try {
        reliability = await reputationRepository.getReliability(userId);
      } catch (_) {}
      try {
        balance = (await recognitionRepository.getWallet(userId))?.balance;
      } catch (_) {}
      emit(CasesLoaded(profile: profile, cases: cases, reliability: reliability, balance: balance));
    } catch (e) {
      emit(CasesError(ApiException.from(e, 'No se pudieron cargar tus casos').message));
    }
  }
}
