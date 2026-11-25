part of 'review_deadline_bloc.dart';

sealed class ReviewDeadlineState {
  const ReviewDeadlineState();
}

class ReviewDeadlineLoading extends ReviewDeadlineState {
  const ReviewDeadlineLoading();
}

class ReviewDeadlineError extends ReviewDeadlineState {
  final String message;

  const ReviewDeadlineError(this.message);
}

class ReviewDeadlineLoaded extends ReviewDeadlineState {
  final List<ReviewDeadlinePolicy> policies; // el plan mensual primero
  final bool saving;
  final String? notice; // confirmación para mostrar una sola vez
  final String? error; // error para mostrar una sola vez

  const ReviewDeadlineLoaded(this.policies, {this.saving = false, this.notice, this.error});

  ReviewDeadlinePolicy? _of(String plan) {
    for (final p in policies) {
      if (p.plan == plan) return p;
    }
    return null;
  }

  ReviewDeadlinePolicy? get premium => _of(ReviewDeadlinePolicy.premium);

  ReviewDeadlinePolicy? get free => _of(ReviewDeadlinePolicy.free);

  // Copia con otra lista o estado de envío; lo que no se indica vuelve a su valor inicial.
  ReviewDeadlineLoaded copyWith({List<ReviewDeadlinePolicy>? policies, bool saving = false, String? notice, String? error}) =>
      ReviewDeadlineLoaded(policies ?? this.policies, saving: saving, notice: notice, error: error);
}
