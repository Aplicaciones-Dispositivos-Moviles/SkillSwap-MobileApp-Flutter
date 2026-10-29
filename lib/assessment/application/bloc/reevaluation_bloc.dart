import 'package:bloc/bloc.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/reevaluation_candidate.dart';
import '../../domain/repositories/verification_case_repository.dart';

part 'reevaluation_event.dart';
part 'reevaluation_state.dart';

// T60 · Reevaluación de un resultado aprobado para el Verificador senior (US37).
class ReevaluationBloc extends Bloc<ReevaluationEvent, ReevaluationState> {
  final VerificationCaseRepository caseRepository;

  ReevaluationBloc({required this.caseRepository}) : super(const ReevaluationLoading()) {
    on<ReevaluationsRequested>(_onRequested);
    on<ReevaluationOrdered>(_onOrdered);
  }

  Future<void> _onRequested(ReevaluationsRequested event, Emitter<ReevaluationState> emit) async {
    final current = state;
    // Una recarga silenciosa deja la lista a la vista (y sus avisos) mientras se actualiza
    if (!event.silent || current is! ReevaluationLoaded) emit(const ReevaluationLoading());
    try {
      final candidates = await caseRepository.getReevaluationCandidates();
      emit(ReevaluationLoaded(candidates));
    } catch (e) {
      final error = ApiException.from(e, 'No se pudieron cargar los resultados');
      emit(error.status == 403 ? const ReevaluationForbidden() : ReevaluationError(error.message));
    }
  }

  Future<void> _onOrdered(ReevaluationOrdered event, Emitter<ReevaluationState> emit) async {
    final current = state;
    if (current is! ReevaluationLoaded || current.busyKey != null) return;
    final justification = event.justification.trim();
    if (justification.isEmpty) {
      emit(current.copyWith(error: 'Escribe la justificación de la reevaluación'));
      return;
    }
    if (justification.length > ReevaluationCandidate.justificationMaxLength) {
      emit(current.copyWith(
        error: 'La justificación no puede pasar de ${ReevaluationCandidate.justificationMaxLength} caracteres',
      ));
      return;
    }
    final candidate = event.candidate;
    emit(current.copyWith(busyKey: candidate.key));
    try {
      await caseRepository.orderReevaluation(
        sourceType: candidate.sourceType,
        sourceId: candidate.sourceId,
        justification: justification,
      );
      emit(current.copyWith(
        candidates: [
          for (final c in current.candidates)
            if (c.key != candidate.key) c,
        ],
        notice: 'Reevaluación ordenada',
      ));
    } catch (e) {
      final error = ApiException.from(e, 'No se pudo ordenar la reevaluación');
      emit(current.copyWith(error: error.message));
      // 409: el resultado cambió desde que se cargó la lista (ya reevaluado o con un caso en curso)
      if (error.status == 409) add(const ReevaluationsRequested(silent: true));
    }
  }
}
