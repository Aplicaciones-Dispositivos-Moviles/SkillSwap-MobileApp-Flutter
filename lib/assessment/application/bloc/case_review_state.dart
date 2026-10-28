part of 'case_review_bloc.dart';

sealed class CaseReviewState {
  const CaseReviewState();
}

class CaseReviewLoading extends CaseReviewState {
  const CaseReviewLoading();
}

class CaseReviewLoaded extends CaseReviewState {
  final CaseDetail detail;
  final bool submitting;
  final String? error; // error al enviar la decisión (el caso sigue en pantalla)

  const CaseReviewLoaded(this.detail, {this.submitting = false, this.error});
}

// La decisión se registró: el caso queda resuelto
class CaseResolved extends CaseReviewState {
  final CaseDetail detail;
  final VerificationCase resolved;

  const CaseResolved(this.detail, this.resolved);
}

class CaseReviewError extends CaseReviewState {
  final String message;

  const CaseReviewError(this.message);
}
