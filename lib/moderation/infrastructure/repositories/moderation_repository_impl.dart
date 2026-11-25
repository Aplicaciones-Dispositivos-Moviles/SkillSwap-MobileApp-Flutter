import 'package:dio/dio.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/dispute.dart';
import '../../domain/models/dispute_evidence.dart';
import '../../domain/repositories/moderation_repository.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  final Dio dio;

  ModerationRepositoryImpl({required this.dio});

  @override
  Future<List<Dispute>> getDisputes({bool resolved = false}) async {
    try {
      final response = await dio.get(
        '/api/v1/disputes',
        queryParameters: {'status': resolved ? 'Resolved' : 'Pending'},
      );
      return [for (final d in (response.data as List)) Dispute.fromJson(d as Map<String, dynamic>)];
    } catch (e) {
      throw ApiException.from(e, 'No se pudieron cargar las disputas');
    }
  }

  @override
  Future<DisputeEvidence> getEvidence(int disputeId) async {
    try {
      final response = await dio.get('/api/v1/disputes/$disputeId/evidence');
      return DisputeEvidence.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e, 'No se pudo abrir la disputa');
    }
  }

  @override
  Future<Dispute> resolveDispute(int disputeId, {required String outcome, required String resolutionNotes}) async {
    try {
      final response = await dio.patch(
        '/api/v1/disputes/$disputeId/resolve',
        data: {'outcome': outcome, 'resolutionNotes': resolutionNotes},
      );
      return Dispute.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e, 'No se pudo registrar tu decisión');
    }
  }
}
