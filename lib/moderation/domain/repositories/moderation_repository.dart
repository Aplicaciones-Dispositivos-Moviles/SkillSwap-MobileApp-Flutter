import '../models/dispute.dart';

abstract class ModerationRepository {
  // US34 · Disputas asignadas a quien consulta, la más antigua primero: las pendientes o, con [resolved], las resueltas.
  // 403 si no es un Verificador habilitado.
  Future<List<Dispute>> getDisputes({bool resolved = false});
}
