import '../../../shared/domain/utils/formatters.dart';

// ShareableCredentialResource: enlace público de una habilidad verificada y el texto para compartir.
// shareText ya incluye la habilidad, los SkillCredits y el enlace.
class ShareableCredential {
  final String skillTag;
  final String skillName;
  final String token;
  final String url;
  final String shareText;
  final DateTime? createdAt;

  const ShareableCredential({
    required this.skillTag,
    required this.skillName,
    required this.token,
    required this.url,
    required this.shareText,
    required this.createdAt,
  });

  factory ShareableCredential.fromJson(Map<String, dynamic> json) => ShareableCredential(
        skillTag: json['skillTag'] as String,
        skillName: (json['skillName'] ?? json['skillTag']) as String,
        token: (json['token'] ?? '') as String,
        url: (json['url'] ?? '') as String,
        shareText: (json['shareText'] ?? '') as String,
        createdAt: parseDate(json['createdAt']),
      );

  // Lo que se publica: el texto del backend, con el enlace al final si no lo trae
  String get publication => shareText.contains(url) ? shareText : '$shareText\n$url';
}
