import 'package:bloc/bloc.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/platform_metrics.dart';
import '../../domain/repositories/reputation_repository.dart';

part 'metrics_event.dart';
part 'metrics_state.dart';

// T64 · Métricas de la plataforma para el Verificador senior (US40).
class MetricsBloc extends Bloc<MetricsEvent, MetricsState> {
  final ReputationRepository reputationRepository;
  final DateTime Function() clock;

  MetricsBloc({required this.reputationRepository, DateTime Function()? clock})
      : clock = clock ?? DateTime.now,
        super(const MetricsInitial()) {
    on<MetricsRequested>(_onRequested);
  }

  Future<void> _onRequested(MetricsRequested event, Emitter<MetricsState> emit) async {
    emit(MetricsLoading(event.days));
    final to = clock();
    final from = to.subtract(Duration(days: event.days - 1));
    try {
      // Las tres consultas van en paralelo
      final results = await Future.wait([
        reputationRepository.getDemand(from, to),
        reputationRepository.getDifficulty(from, to),
        reputationRepository.getVerifiers(),
      ]);
      emit(MetricsLoaded(
        event.days,
        demand: results[0] as DemandMetrics,
        difficulty: results[1] as DifficultyMetrics,
        verifiers: results[2] as List<VerifierMetric>,
      ));
    } catch (e) {
      final error = ApiException.from(e, 'No se pudieron cargar las métricas');
      emit(error.status == 403 ? MetricsForbidden(event.days) : MetricsError(event.days, error.message));
    }
  }
}
