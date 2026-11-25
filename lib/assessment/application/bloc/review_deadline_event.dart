part of 'review_deadline_bloc.dart';

sealed class ReviewDeadlineEvent {
  const ReviewDeadlineEvent();
}

class ReviewDeadlinesRequested extends ReviewDeadlineEvent {
  const ReviewDeadlinesRequested();
}

// Los valores llegan como los escribió el Verificador; el BLoC los valida antes de llamar al backend.
class ReviewDeadlinesSaved extends ReviewDeadlineEvent {
  final String premiumHours;
  final String freeBusinessDays;

  const ReviewDeadlinesSaved({required this.premiumHours, required this.freeBusinessDays});
}
