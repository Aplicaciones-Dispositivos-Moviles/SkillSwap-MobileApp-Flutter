import '../models/platform_metrics.dart';
import '../models/verifier_reliability.dart';

abstract class ReputationRepository {
  // Confiabilidad del Verificador; null si aún no tiene (404).
  Future<VerifierReliability?> getReliability(int verifierUserId);

  // Las tres consultas de métricas responden 403 si quien pregunta no es Verificador senior.
  Future<DemandMetrics> getDemand(DateTime from, DateTime to);
  Future<DifficultyMetrics> getDifficulty(DateTime from, DateTime to);
  // order: asc (menor confiabilidad primero) o desc (por defecto).
  Future<List<VerifierMetric>> getVerifiers({String order = 'desc'});
}
