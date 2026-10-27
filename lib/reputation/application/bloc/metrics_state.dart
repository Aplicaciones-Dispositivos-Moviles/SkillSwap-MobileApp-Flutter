part of 'metrics_bloc.dart';

sealed class MetricsState {
  final int days;

  const MetricsState(this.days);
}

class MetricsInitial extends MetricsState {
  const MetricsInitial() : super(30);
}

class MetricsLoading extends MetricsState {
  const MetricsLoading(super.days);
}

class MetricsLoaded extends MetricsState {
  final DemandMetrics demand;
  final DifficultyMetrics difficulty;
  final List<VerifierMetric> verifiers;

  const MetricsLoaded(super.days, {required this.demand, required this.difficulty, required this.verifiers});
}

// 403: quien consulta no es Verificador senior
class MetricsForbidden extends MetricsState {
  const MetricsForbidden(super.days);
}

class MetricsError extends MetricsState {
  final String message;

  const MetricsError(super.days, this.message);
}
