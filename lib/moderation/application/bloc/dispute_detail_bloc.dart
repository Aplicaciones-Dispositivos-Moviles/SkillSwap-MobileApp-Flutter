import 'package:bloc/bloc.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/dispute.dart';
import '../../domain/models/dispute_evidence.dart';
import '../../domain/repositories/moderation_repository.dart';

part 'dispute_detail_event.dart';
part 'dispute_detail_state.dart';

// US35 · Resolución de un certificado sospechoso: el Verificador revisa la evidencia y lo verifica o lo rechaza.
class DisputeDetailBloc extends Bloc<DisputeDetailEvent, DisputeDetailState> {
  final ModerationRepository moderationRepository;

  DisputeDetailBloc({required this.moderationRepository}) : super(const DisputeDetailLoading()) {
    on<DisputeEvidenceRequested>(_onRequested);
    on<DisputeResolutionSubmitted>(_onSubmitted);
  }

  Future<void> _onRequested(DisputeEvidenceRequested event, Emitter<DisputeDetailState> emit) async {
    emit(const DisputeDetailLoading());
    try {
      emit(DisputeDetailLoaded(await moderationRepository.getEvidence(event.disputeId)));
    } catch (e) {
      emit(DisputeDetailError(ApiException.from(e, 'No se pudo abrir la disputa').message));
    }
  }

  Future<void> _onSubmitted(DisputeResolutionSubmitted event, Emitter<DisputeDetailState> emit) async {
    final current = state;
    if (current is! DisputeDetailLoaded || current.submitting) return;
    final evidence = current.evidence;
    if (!evidence.dispute.isPending) return;
    final notes = event.notes.trim();
    if (notes.isEmpty) {
      emit(DisputeDetailLoaded(evidence, error: 'Escribe tus observaciones antes de decidir'));
      return;
    }
    if (notes.length > Dispute.notesMaxLength) {
      emit(DisputeDetailLoaded(
        evidence,
        error: 'Las observaciones no pueden pasar de ${Dispute.notesMaxLength} caracteres',
      ));
      return;
    }
    emit(DisputeDetailLoaded(evidence, submitting: true));
    try {
      final resolved = await moderationRepository.resolveDispute(
        evidence.dispute.id,
        outcome: event.verify ? Dispute.upheld : Dispute.overturned,
        resolutionNotes: notes,
      );
      emit(DisputeResolved(evidence, resolved));
    } catch (e) {
      final error = ApiException.from(e, 'No se pudo registrar tu decisión');
      emit(DisputeDetailLoaded(evidence, error: error.message, outdated: error.status == 409));
    }
  }
}
