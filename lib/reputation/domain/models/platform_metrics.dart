// Métricas agregadas de la plataforma (US40, solo Verificador senior).

class SkillDemand {
  final String skillTag;
  final String skillName;
  final int pathCount;

  const SkillDemand(this.skillTag, this.skillName, this.pathCount);

  factory SkillDemand.fromJson(Map<String, dynamic> json) => SkillDemand(
        json['skillTag'] as String,
        (json['skillName'] ?? json['skillTag']) as String,
        (json['pathCount'] as num? ?? 0).toInt(),
      );
}

class CertificationDemand {
  final String courseName;
  final int count;

  const CertificationDemand(this.courseName, this.count);

  factory CertificationDemand.fromJson(Map<String, dynamic> json) =>
      CertificationDemand(json['courseName'] as String, (json['count'] as num? ?? 0).toInt());
}

// GET /api/v1/metrics/demand
class DemandMetrics {
  final List<SkillDemand> topSkills;
  final List<CertificationDemand> topCertifications;

  const DemandMetrics(this.topSkills, this.topCertifications);

  factory DemandMetrics.fromJson(Map<String, dynamic> json) => DemandMetrics(
        [for (final s in (json['topSkills'] as List? ?? const [])) SkillDemand.fromJson(s as Map<String, dynamic>)],
        [
          for (final c in (json['topCertifications'] as List? ?? const []))
            CertificationDemand.fromJson(c as Map<String, dynamic>)
        ],
      );
}

class SkillDifficulty {
  final String skillTag;
  final String skillName;
  final int attempts;
  final int failed;
  final double failureRate; // 0 a 1

  const SkillDifficulty(this.skillTag, this.skillName, this.attempts, this.failed, this.failureRate);

  factory SkillDifficulty.fromJson(Map<String, dynamic> json) => SkillDifficulty(
        json['skillTag'] as String,
        (json['skillName'] ?? json['skillTag']) as String,
        (json['attempts'] as num? ?? 0).toInt(),
        (json['failed'] as num? ?? 0).toInt(),
        (json['failureRate'] as num? ?? 0).toDouble(),
      );

  // Lo que muestra el mock-up: la tasa de aprobación (lo contrario de la de fallos)
  double get approvalRate => (1 - failureRate).clamp(0, 1).toDouble();
}

class SubTopicDifficulty {
  final String skillName;
  final String subTopic;
  final int weakCount;
  final double shareOfFailures;

  const SubTopicDifficulty(this.skillName, this.subTopic, this.weakCount, this.shareOfFailures);

  factory SubTopicDifficulty.fromJson(Map<String, dynamic> json) => SubTopicDifficulty(
        (json['skillName'] ?? json['skillTag']) as String,
        json['subTopic'] as String,
        (json['weakCount'] as num? ?? 0).toInt(),
        (json['shareOfFailures'] as num? ?? 0).toDouble(),
      );
}

// GET /api/v1/metrics/difficulty
class DifficultyMetrics {
  final List<SkillDifficulty> skills;
  final List<SubTopicDifficulty> subTopics;

  const DifficultyMetrics(this.skills, this.subTopics);

  factory DifficultyMetrics.fromJson(Map<String, dynamic> json) => DifficultyMetrics(
        [for (final s in (json['skills'] as List? ?? const [])) SkillDifficulty.fromJson(s as Map<String, dynamic>)],
        [
          for (final s in (json['subTopics'] as List? ?? const []))
            SubTopicDifficulty.fromJson(s as Map<String, dynamic>)
        ],
      );
}

class VerifierMetric {
  final int verifierUserId;
  final String? fullName;
  final int score;
  final String rank;
  final int resolvedCasesCount;
  final int missedDeadlinesCount;
  final bool seniorVerifier;
  final bool suspended;
  final double? averageResolutionHours;

  const VerifierMetric({
    required this.verifierUserId,
    required this.fullName,
    required this.score,
    required this.rank,
    required this.resolvedCasesCount,
    required this.missedDeadlinesCount,
    required this.seniorVerifier,
    required this.suspended,
    required this.averageResolutionHours,
  });

  factory VerifierMetric.fromJson(Map<String, dynamic> json) => VerifierMetric(
        verifierUserId: (json['verifierUserId'] as num).toInt(),
        fullName: json['fullName'] as String?,
        score: (json['score'] as num? ?? 0).toInt(),
        rank: (json['rank'] ?? 'Bronze') as String,
        resolvedCasesCount: (json['resolvedCasesCount'] as num? ?? 0).toInt(),
        missedDeadlinesCount: (json['missedDeadlinesCount'] as num? ?? 0).toInt(),
        seniorVerifier: (json['seniorVerifier'] ?? false) as bool,
        suspended: (json['suspended'] ?? false) as bool,
        averageResolutionHours: (json['averageResolutionHours'] as num?)?.toDouble(),
      );

  String get displayName => (fullName == null || fullName!.isEmpty) ? 'Verificador #$verifierUserId' : fullName!;

  // Solo se suspende a quien tiene confiabilidad menor a 60 (el backend responde 409 si no); máximo 2000 caracteres.
  static const suspensionThreshold = 60;
  static const justificationMaxLength = 2000;

  bool get canBeSuspended => !suspended && score < suspensionThreshold;

  VerifierMetric copyWith({bool? suspended}) => VerifierMetric(
        verifierUserId: verifierUserId,
        fullName: fullName,
        score: score,
        rank: rank,
        resolvedCasesCount: resolvedCasesCount,
        missedDeadlinesCount: missedDeadlinesCount,
        seniorVerifier: seniorVerifier,
        suspended: suspended ?? this.suspended,
        averageResolutionHours: averageResolutionHours,
      );

  // Porcentaje de casos resueltos dentro del plazo; null si todavía no resolvió ninguno
  int? get onTimePercent {
    if (resolvedCasesCount == 0) return null;
    final onTime = (resolvedCasesCount - missedDeadlinesCount).clamp(0, resolvedCasesCount);
    return (onTime * 100 / resolvedCasesCount).round();
  }
}

// GET /api/v1/metrics/verifiers (ordenados por confiabilidad, el mejor primero)
List<VerifierMetric> verifierMetricsFromJson(Map<String, dynamic> json) =>
    [for (final v in (json['verifiers'] as List? ?? const [])) VerifierMetric.fromJson(v as Map<String, dynamic>)];
