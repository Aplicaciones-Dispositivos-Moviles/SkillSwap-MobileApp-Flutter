import '../models/dispute.dart';
import '../models/dispute_evidence.dart';

abstract class ModerationRepository {
  // US34 · Disputas asignadas a quien consulta, la más antigua primero: las pendientes o, con [resolved], las resueltas.
  // 403 si no es un Verificador habilitado.
  Future<List<Dispute>> getDisputes({bool resolved = false});

  // US35 · La disputa con el certificado en revisión y un enlace temporal a su archivo (vence a los 15 minutos).
  // 403 si no eres su revisor; 404 si no existe.
  Future<DisputeEvidence> getEvidence(int disputeId);

  // US35 · outcome: Upheld (verifica el certificado) | Overturned (lo rechaza). Las observaciones son obligatorias.
  // 409 si la disputa ya se resolvió o el certificado dejó de ser sospechoso.
  Future<Dispute> resolveDispute(int disputeId, {required String outcome, required String resolutionNotes});
}
