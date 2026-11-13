import '../models/reevaluation_candidate.dart';
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

  // T62 · Verificador senior: suspende a otro Verificador con confiabilidad menor a 60 (409 si no aplica).
  Future<VerifierProfile> suspendVerifier(int verifierUserId, String justification);

  // T62 · Reactiva a un Verificador suspendido (409 si no está suspendido).
  Future<VerifierProfile> reinstateVerifier(int verifierUserId);

  // T60 · Verificador senior: resultados aprobados de otros Estudiantes que se pueden reevaluar (403 si no es senior).
  Future<List<ReevaluationCandidate>> getReevaluationCandidates({int limit = 50});

  // T60 · sourceType: Attempt | Case. 409 si el resultado ya no se puede reevaluar.
  Future<void> orderReevaluation({required String sourceType, required int sourceId, required String justification});
}
