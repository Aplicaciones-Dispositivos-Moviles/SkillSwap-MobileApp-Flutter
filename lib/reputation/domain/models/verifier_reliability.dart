// VerifierReliabilityResource: confiabilidad del Verificador (0 a 100) y su rango.
class VerifierReliability {
  final int verifierUserId;
  final int score;
  final String rank; // Bronze | Silver | Gold
  final bool seniorVerifier;
  final int resolvedCasesCount;
  final int missedDeadlinesCount;

  const VerifierReliability({
    required this.verifierUserId,
    required this.score,
    required this.rank,
    required this.seniorVerifier,
    required this.resolvedCasesCount,
    required this.missedDeadlinesCount,
  });

  factory VerifierReliability.fromJson(Map<String, dynamic> json) => VerifierReliability(
        verifierUserId: (json['verifierUserId'] as num).toInt(),
        score: (json['score'] as num? ?? 0).toInt(),
        rank: (json['rank'] ?? 'Bronze') as String,
        seniorVerifier: (json['seniorVerifier'] ?? false) as bool,
        resolvedCasesCount: (json['resolvedCasesCount'] as num? ?? 0).toInt(),
        missedDeadlinesCount: (json['missedDeadlinesCount'] as num? ?? 0).toInt(),
      );

  // El rango como se muestra en la app
  String get rankLabel => rankName(rank);
}

String rankName(String rank) => switch (rank) {
      'Gold' => 'Oro',
      'Silver' => 'Plata',
      _ => 'Bronce',
    };
