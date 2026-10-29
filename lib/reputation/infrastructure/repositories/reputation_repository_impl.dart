import 'package:dio/dio.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../../shared/domain/utils/formatters.dart';
import '../../domain/models/platform_metrics.dart';
import '../../domain/models/verifier_reliability.dart';
import '../../domain/repositories/reputation_repository.dart';

class ReputationRepositoryImpl implements ReputationRepository {
  final Dio dio;

  ReputationRepositoryImpl({required this.dio});

  @override
  Future<VerifierReliability?> getReliability(int verifierUserId) async {
    try {
      final response = await dio.get('/api/v1/verifier-reliabilities/$verifierUserId');
      return VerifierReliability.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.from(e, 'No se pudo cargar tu confiabilidad');
    }
  }

  Map<String, String> _period(DateTime from, DateTime to) => {'from': isoDay(from), 'to': isoDay(to)};

  @override
  Future<DemandMetrics> getDemand(DateTime from, DateTime to) async {
    try {
      final response = await dio.get('/api/v1/metrics/demand', queryParameters: _period(from, to));
      return DemandMetrics.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e, 'No se pudo cargar la demanda de habilidades');
    }
  }

  @override
  Future<DifficultyMetrics> getDifficulty(DateTime from, DateTime to) async {
    try {
      final response = await dio.get('/api/v1/metrics/difficulty', queryParameters: _period(from, to));
      return DifficultyMetrics.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e, 'No se pudo cargar la tasa de aprobación');
    }
  }

  @override
  Future<List<VerifierMetric>> getVerifiers({String order = 'desc'}) async {
    try {
      final response = await dio.get('/api/v1/metrics/verifiers', queryParameters: {'order': order});
      return verifierMetricsFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e, 'No se pudo cargar el desempeño de los Verificadores');
    }
  }
}
