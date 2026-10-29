import '../../../shared/domain/utils/formatters.dart';

// ReevaluationCandidateResource: un resultado aprobado que un Verificador senior puede mandar a reevaluar.
// No trae datos del Estudiante.
class ReevaluationCandidate {
  final String sourceType; // Attempt (intento de quiz aprobado) | Case (caso aprobado)
  final int sourceId;
  final String skillTag;
  final String? caseType; // Quiz | MiniProject; null en intentos
  final DateTime? resolvedAt;
  final String? approvedByName; // solo en casos; puede venir null

  const ReevaluationCandidate({
    required this.sourceType,
    required this.sourceId,
    required this.skillTag,
    required this.caseType,
    required this.resolvedAt,
    required this.approvedByName,
  });

  // La justificación es obligatoria y el backend acepta hasta 2000 caracteres.
  static const justificationMaxLength = 2000;

  factory ReevaluationCandidate.fromJson(Map<String, dynamic> json) => ReevaluationCandidate(
        sourceType: (json['sourceType'] ?? 'Attempt') as String,
        sourceId: (json['sourceId'] as num).toInt(),
        skillTag: (json['skillTag'] ?? '') as String,
        caseType: json['caseType'] as String?,
        resolvedAt: parseDate(json['resolvedAt']),
        approvedByName: json['approvedByName'] as String?,
      );

  // Identifica al resultado (un intento y un caso pueden tener el mismo id)
  String get key => '$sourceType-$sourceId';

  String get kindLabel => sourceType == 'Case'
      ? (caseType == 'MiniProject' ? 'Mini proyecto aprobado' : 'Quiz aprobado con revisión')
      : 'Quiz aprobado';
}
