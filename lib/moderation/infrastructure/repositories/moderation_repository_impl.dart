import 'package:dio/dio.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/dispute.dart';
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
}
