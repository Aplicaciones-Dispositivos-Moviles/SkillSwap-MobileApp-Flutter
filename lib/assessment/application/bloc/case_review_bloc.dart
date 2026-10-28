import 'package:bloc/bloc.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/verification_case.dart';
import '../../domain/repositories/verification_case_repository.dart';

part 'case_review_event.dart';
part 'case_review_state.dart';

// T71 · Revisión del caso con la rúbrica y registro de la decisión (US25, mock-up 14).
class CaseReviewBloc extends Bloc<CaseReviewEvent, CaseReviewState> {
  final VerificationCaseRepository caseRepository;

  CaseReviewBloc({required this.caseRepository}) : super(const CaseReviewLoading()) {
    on<CaseReviewRequested>(_onRequested);
    on<CaseDecisionSubmitted>(_onSubmitted);
  }

  Future<void> _onRequested(CaseReviewRequested event, Emitter<CaseReviewState> emit) async {
    emit(const CaseReviewLoading());
    try {
      emit(CaseReviewLoaded(await caseRepository.getCaseDetail(event.caseId)));
    } catch (e) {
      emit(CaseReviewError(ApiException.from(e, 'No se pudo abrir el caso').message));
    }
  }

  Future<void> _onSubmitted(CaseDecisionSubmitted event, Emitter<CaseReviewState> emit) async {
    final current = state;
    if (current is! CaseReviewLoaded || current.submitting) return;
    if (event.rubricNotes.trim().isEmpty) {
      emit(CaseReviewLoaded(current.detail, error: 'Califica la rúbrica antes de decidir'));
      return;
    }
    emit(CaseReviewLoaded(current.detail, submitting: true));
    try {
      final resolved = await caseRepository.resolveCase(
        current.detail.verificationCase.id,
        decision: event.approve ? 'Approved' : 'Rejected',
        rubricNotes: event.rubricNotes,
      );
      emit(CaseResolved(current.detail, resolved));
    } catch (e) {
      emit(CaseReviewLoaded(current.detail, error: ApiException.from(e, 'No se pudo registrar tu decisión').message));
    }
  }
}
