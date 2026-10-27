part of 'metrics_bloc.dart';

sealed class MetricsEvent {
  const MetricsEvent();
}

// Carga (o recarga) las métricas de los últimos [days] días.
class MetricsRequested extends MetricsEvent {
  final int days;

  const MetricsRequested({this.days = 30});
}
