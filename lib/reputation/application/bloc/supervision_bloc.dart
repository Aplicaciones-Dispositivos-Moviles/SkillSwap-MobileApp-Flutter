import 'package:bloc/bloc.dart';

import '../../../assessment/domain/repositories/verification_case_repository.dart';
import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/platform_metrics.dart';
import '../../domain/repositories/reputation_repository.dart';

part 'supervision_event.dart';
part 'supervision_state.dart';

// T62 · Supervisión de Verificadores para el Verificador senior (US38): suspender o reactivar.
class SupervisionBloc extends Bloc<SupervisionEvent, SupervisionState> {
  final int userId;
  final ReputationRepository reputationRepository;
  final VerificationCaseRepository caseRepository;

  SupervisionBloc({required this.userId, required this.reputationRepository, required this.caseRepository})
      : super(const SupervisionLoading()) {
    on<SupervisionRequested>(_onRequested);
    on<VerifierSuspended>(_onSuspended);
    on<VerifierReinstated>(_onReinstated);
  }

  Future<void> _onRequested(SupervisionRequested event, Emitter<SupervisionState> emit) async {
    emit(const SupervisionLoading());
    try {
      // De menor a mayor confiabilidad, sin uno mismo (el backend no deja suspenderse a sí mismo)
      final all = await reputationRepository.getVerifiers(order: 'asc');
      emit(SupervisionLoaded([
        for (final v in all)
          if (v.verifierUserId != userId) v,
      ]));
    } catch (e) {
      final error = ApiException.from(e, 'No se pudo cargar a los Verificadores');
      emit(error.status == 403 ? const SupervisionForbidden() : SupervisionError(error.message));
    }
  }

  Future<void> _onSuspended(VerifierSuspended event, Emitter<SupervisionState> emit) async {
    final current = state;
    if (current is! SupervisionLoaded || current.busyUserId != null) return;
    final justification = event.justification.trim();
    if (justification.isEmpty) {
      emit(current.copyWith(error: 'Escribe la justificación de la suspensión'));
      return;
    }
    if (justification.length > VerifierMetric.justificationMaxLength) {
      emit(current.copyWith(
        error: 'La justificación no puede pasar de ${VerifierMetric.justificationMaxLength} caracteres',
      ));
      return;
    }
    emit(current.copyWith(busyUserId: event.verifierUserId));
    try {
      await caseRepository.suspendVerifier(event.verifierUserId, justification);
      emit(current.copyWith(
        verifiers: _withSuspended(current.verifiers, event.verifierUserId, true),
        notice: 'Verificador suspendido',
      ));
    } catch (e) {
      emit(current.copyWith(error: ApiException.from(e, 'No se pudo suspender al Verificador').message));
    }
  }

  Future<void> _onReinstated(VerifierReinstated event, Emitter<SupervisionState> emit) async {
    final current = state;
    if (current is! SupervisionLoaded || current.busyUserId != null) return;
    emit(current.copyWith(busyUserId: event.verifierUserId));
    try {
      await caseRepository.reinstateVerifier(event.verifierUserId);
      emit(current.copyWith(
        verifiers: _withSuspended(current.verifiers, event.verifierUserId, false),
        notice: 'Verificador reactivado',
      ));
    } catch (e) {
      emit(current.copyWith(error: ApiException.from(e, 'No se pudo reactivar al Verificador').message));
    }
  }

  List<VerifierMetric> _withSuspended(List<VerifierMetric> verifiers, int verifierUserId, bool suspended) => [
        for (final v in verifiers) v.verifierUserId == verifierUserId ? v.copyWith(suspended: suspended) : v,
      ];
}
