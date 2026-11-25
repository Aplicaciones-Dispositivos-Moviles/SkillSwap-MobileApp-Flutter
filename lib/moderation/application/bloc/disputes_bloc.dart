import 'package:bloc/bloc.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/dispute.dart';
import '../../domain/repositories/moderation_repository.dart';

part 'disputes_event.dart';
part 'disputes_state.dart';

// US34 · Consulta de disputas: los certificados sospechosos que le tocan al Verificador, pendientes o resueltos.
class DisputesBloc extends Bloc<DisputesEvent, DisputesState> {
  final ModerationRepository moderationRepository;

  DisputesBloc({required this.moderationRepository}) : super(const DisputesLoading()) {
    on<DisputesRequested>(_onRequested);
  }

  Future<void> _onRequested(DisputesRequested event, Emitter<DisputesState> emit) async {
    emit(const DisputesLoading());
    try {
      final disputes = await moderationRepository.getDisputes(resolved: event.resolved);
      emit(DisputesLoaded(disputes, resolved: event.resolved));
    } catch (e) {
      final error = ApiException.from(e, 'No se pudieron cargar las disputas');
      emit(error.status == 403 ? const DisputesForbidden() : DisputesError(error.message));
    }
  }
}
