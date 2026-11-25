import '../../../shared/domain/utils/formatters.dart';
import 'dispute.dart';

// CertificateEvidenceResource: el certificado en revisión, como lo ve el Verificador (sin su dueño).
class CertificateEvidence {
  final int id;
  final String holderName; // titular que leyó el OCR
  final String institutionName;
  final String courseName;
  final DateTime? issueDate;
  final String certificateNumber;
  final String verificationCode;
  final String verificationUrl;
  final String status; // Suspicious mientras espera; luego Verified o Rejected
  final String riskLevel; // LowRisk | Review | HighRisk
  final bool holderNameMismatch; // el titular no es el nombre registrado del dueño
  final DateTime? createdAt;
  final String? fileUrl; // enlace temporal al archivo; vence a los 15 minutos

  const CertificateEvidence({
    required this.id,
    required this.holderName,
    required this.institutionName,
    required this.courseName,
    required this.issueDate,
    required this.certificateNumber,
    required this.verificationCode,
    required this.verificationUrl,
    required this.status,
    required this.riskLevel,
    required this.holderNameMismatch,
    required this.createdAt,
    required this.fileUrl,
  });

  factory CertificateEvidence.fromJson(Map<String, dynamic> json) => CertificateEvidence(
        id: (json['id'] as num).toInt(),
        holderName: (json['holderName'] ?? '') as String,
        institutionName: (json['institutionName'] ?? '') as String,
        courseName: (json['courseName'] ?? '') as String,
        issueDate: parseDate(json['issueDate']),
        certificateNumber: (json['certificateNumber'] ?? '') as String,
        verificationCode: (json['verificationCode'] ?? '') as String,
        verificationUrl: (json['verificationUrl'] ?? '') as String,
        status: (json['status'] ?? 'Suspicious') as String,
        riskLevel: (json['riskLevel'] ?? 'Review') as String,
        holderNameMismatch: (json['holderNameMismatch'] ?? false) as bool,
        createdAt: parseDate(json['createdAt']),
        fileUrl: json['fileUrl'] as String?,
      );

  String get riskLabel => switch (riskLevel) {
        'LowRisk' => 'Riesgo bajo',
        'HighRisk' => 'Riesgo alto',
        _ => 'Requiere revisión',
      };

  // dd/MM/yyyy; la fecha de emisión no trae hora
  String get issueDateLabel {
    final d = issueDate;
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

// DisputeEvidenceResource: la disputa con el certificado que hay que decidir.
class DisputeEvidence {
  final Dispute dispute;
  final CertificateEvidence? certificate; // null si el certificado ya no existe

  const DisputeEvidence({required this.dispute, required this.certificate});

  factory DisputeEvidence.fromJson(Map<String, dynamic> json) => DisputeEvidence(
        dispute: Dispute.fromJson(json['dispute'] as Map<String, dynamic>),
        certificate: json['certificate'] == null
            ? null
            : CertificateEvidence.fromJson(json['certificate'] as Map<String, dynamic>),
      );
}
