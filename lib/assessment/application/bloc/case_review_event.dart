part of 'case_review_bloc.dart';

sealed class CaseReviewEvent {
  const CaseReviewEvent();
}

class CaseReviewRequested extends CaseReviewEvent {
  final int caseId;

  const CaseReviewRequested(this.caseId);
}

// El Verificador envía su decisión con las notas de la rúbrica.
class CaseDecisionSubmitted extends CaseReviewEvent {
  final bool approve;
  final String rubricNotes;

  const CaseDecisionSubmitted({required this.approve, required this.rubricNotes});
}
