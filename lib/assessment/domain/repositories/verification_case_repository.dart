import '../models/verification_case.dart';
import '../models/verifier_profile.dart';

abstract class VerificationCaseRepository {
  // Perfil de Verificador de quien inició sesión; null si todavía no es Verificador (404).
  Future<VerifierProfile?> getMyProfile();

  // Casos asignados, el más reciente primero.
  Future<List<VerificationCase>> getAssignedCases();

  Future<CaseDetail> getCaseDetail(int caseId);

  // decision: Approved | Rejected. 409 si el caso ya fue resuelto.
  Future<VerificationCase> resolveCase(int caseId, {required String decision, required String rubricNotes});

  // Activa o pausa la recepción de casos nuevos (T72); devuelve el perfil actualizado.
  Future<VerifierProfile> updateAvailability(bool available);
}
