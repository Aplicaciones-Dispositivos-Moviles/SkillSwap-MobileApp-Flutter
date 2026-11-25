import '../../../shared/domain/utils/formatters.dart';

// DisputeResource: un certificado sospechoso que se le asignó al Verificador para decidirlo.
// La revisión es ciega: no trae quién lo subió ni de quién es.
class Dispute {
  final int id;
  final String sourceType; // CertificateReview (el único origen que abre hoy el backend)
  final int sourceReferenceId; // el certificado en revisión
  final String reason; // reglas que lo hicieron sospechoso, separadas por coma
  final String status; // Pending | Resolved
  final String? outcome; // Upheld (legítimo) | Overturned (fraudulento); null hasta resolverla
  final String? resolutionNotes;
  final bool assignedToSenior;
  final DateTime? assignedAt;
  final DateTime? raisedAt;
  final DateTime? resolvedAt;

  const Dispute({
    required this.id,
    required this.sourceType,
    required this.sourceReferenceId,
    required this.reason,
    required this.status,
    required this.outcome,
    required this.resolutionNotes,
    required this.assignedToSenior,
    required this.assignedAt,
    required this.raisedAt,
    required this.resolvedAt,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) => Dispute(
        id: (json['id'] as num).toInt(),
        sourceType: (json['sourceType'] ?? 'CertificateReview') as String,
        sourceReferenceId: (json['sourceReferenceId'] as num? ?? 0).toInt(),
        reason: (json['reason'] ?? '') as String,
        status: (json['status'] ?? 'Pending') as String,
        outcome: json['outcome'] as String?,
        resolutionNotes: json['resolutionNotes'] as String?,
        assignedToSenior: (json['assignedToSenior'] ?? false) as bool,
        assignedAt: parseDate(json['assignedAt']),
        raisedAt: parseDate(json['raisedAt']),
        resolvedAt: parseDate(json['resolvedAt']),
      );

  // Las observaciones de la resolución son obligatorias y el backend acepta hasta 2000 caracteres.
  static const notesMaxLength = 2000;

  // Resultados que acepta el backend: Upheld verifica el certificado y Overturned lo rechaza.
  static const upheld = 'Upheld';
  static const overturned = 'Overturned';

  bool get isPending => status == 'Pending';

  // Motivos que el backend detectó, con su texto en español; uno desconocido se muestra tal cual.
  static const reasonLabels = {
    'DuplicateFile': 'Archivo ya registrado por otro Estudiante',
    'DuplicateCertificateNumber': 'Número de certificado repetido',
    'DuplicateVerificationCode': 'Código de verificación repetido',
    'HolderNameMismatch': 'El titular no coincide con el nombre registrado',
    'OcrInconsistencies': 'Datos inconsistentes en la lectura del certificado',
  };

  List<String> get reasons => [
        for (final r in reason.split(','))
          if (r.trim().isNotEmpty) reasonLabels[r.trim()] ?? r.trim(),
      ];

  String get sourceLabel => sourceType == 'CertificateReview' ? 'Certificado sospechoso' : 'Disputa';

  // Cómo quedó, una vez resuelta
  String? get outcomeLabel => switch (outcome) {
        'Upheld' => 'Certificado verificado',
        'Overturned' => 'Certificado rechazado',
        _ => null,
      };
}
