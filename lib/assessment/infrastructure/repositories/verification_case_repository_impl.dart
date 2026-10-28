import 'package:dio/dio.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/verification_case.dart';
import '../../domain/models/verifier_profile.dart';
import '../../domain/repositories/verification_case_repository.dart';

class VerificationCaseRepositoryImpl implements VerificationCaseRepository {
  final Dio dio;

  VerificationCaseRepositoryImpl({required this.dio});

  @override
  Future<VerifierProfile?> getMyProfile() async {
    try {
      final response = await dio.get('/api/v1/verifier-profiles/me');
      return VerifierProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.from(e, 'No se pudo cargar tu perfil de Verificador');
    }
  }

  @override
  Future<List<VerificationCase>> getAssignedCases() async {
    try {
      final response = await dio.get('/api/v1/verification-cases');
      return [
        for (final c in (response.data as List)) VerificationCase.fromJson(c as Map<String, dynamic>),
      ];
    } catch (e) {
      throw ApiException.from(e, 'No se pudieron cargar tus casos');
    }
  }

  @override
  Future<CaseDetail> getCaseDetail(int caseId) async {
    try {
      final response = await dio.get('/api/v1/verification-cases/$caseId');
      return CaseDetail.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e, 'No se pudo abrir el caso');
    }
  }

  @override
  Future<VerificationCase> resolveCase(int caseId, {required String decision, required String rubricNotes}) async {
    try {
      final response = await dio.patch(
        '/api/v1/verification-cases/$caseId/decision',
        data: {'decision': decision, 'rubricNotes': rubricNotes},
      );
      return VerificationCase.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const ApiException('Este caso ya fue resuelto', status: 409);
      }
      throw ApiException.from(e, 'No se pudo registrar tu decisión');
    }
  }
}
