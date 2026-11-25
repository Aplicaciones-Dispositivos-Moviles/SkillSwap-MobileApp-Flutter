import 'package:bloc/bloc.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/review_deadline_policy.dart';
import '../../domain/repositories/verification_case_repository.dart';

part 'review_deadline_event.dart';
part 'review_deadline_state.dart';

// US39 · Plazo de actividad: el Verificador senior define en cuánto se resuelven los casos de cada plan.
class ReviewDeadlineBloc extends Bloc<ReviewDeadlineEvent, ReviewDeadlineState> {
  final VerificationCaseRepository caseRepository;

  ReviewDeadlineBloc({required this.caseRepository}) : super(const ReviewDeadlineLoading()) {
    on<ReviewDeadlinesRequested>(_onRequested);
    on<ReviewDeadlinesSaved>(_onSaved);
  }

  Future<void> _onRequested(ReviewDeadlinesRequested event, Emitter<ReviewDeadlineState> emit) async {
    emit(const ReviewDeadlineLoading());
    try {
      emit(ReviewDeadlineLoaded(await caseRepository.getReviewDeadlines()));
    } catch (e) {
      emit(ReviewDeadlineError(ApiException.from(e, 'No se pudo cargar el plazo de actividad').message));
    }
  }

  Future<void> _onSaved(ReviewDeadlinesSaved event, Emitter<ReviewDeadlineState> emit) async {
    final current = state;
    if (current is! ReviewDeadlineLoaded || current.saving) return;
    final hours = int.tryParse(event.premiumHours.trim());
    if (hours == null || hours < 1 || hours > ReviewDeadlinePolicy.premiumMaxHours) {
      emit(current.copyWith(
        error: 'Las horas del plan mensual van de 1 a ${ReviewDeadlinePolicy.premiumMaxHours}',
      ));
      return;
    }
    final days = int.tryParse(event.freeBusinessDays.trim());
    if (days == null || days < 1 || days > ReviewDeadlinePolicy.freeMaxBusinessDays) {
      emit(current.copyWith(
        error: 'Los días hábiles del plan gratuito van de 1 a ${ReviewDeadlinePolicy.freeMaxBusinessDays}',
      ));
      return;
    }
    emit(current.copyWith(saving: true));
    try {
      final policies = await caseRepository.defineReviewDeadlines(
        premiumPlanHours: hours,
        freePlanBusinessDays: days,
      );
      emit(current.copyWith(policies: policies, notice: 'Plazo de actividad guardado'));
    } catch (e) {
      emit(current.copyWith(error: ApiException.from(e, 'No se pudo guardar el plazo de actividad').message));
    }
  }
}
