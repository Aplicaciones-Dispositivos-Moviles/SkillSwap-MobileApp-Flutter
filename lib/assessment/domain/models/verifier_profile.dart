// VerifierProfileResource: habilidades que puede revisar y si recibe casos.
class VerifierProfile {
  final int id;
  final int verifierUserId;
  final List<String> skillTags;
  final bool available;
  final bool verified;
  final double rating;
  final int reviewCount;
  final bool suspended;

  const VerifierProfile({
    required this.id,
    required this.verifierUserId,
    required this.skillTags,
    required this.available,
    required this.verified,
    required this.rating,
    required this.reviewCount,
    required this.suspended,
  });

  factory VerifierProfile.fromJson(Map<String, dynamic> json) => VerifierProfile(
        id: (json['id'] as num).toInt(),
        verifierUserId: (json['verifierUserId'] as num).toInt(),
        skillTags: [for (final t in (json['skillTags'] as List? ?? const [])) t as String],
        available: (json['available'] ?? false) as bool,
        verified: (json['verified'] ?? true) as bool,
        rating: (json['rating'] as num? ?? 0).toDouble(),
        reviewCount: (json['reviewCount'] as num? ?? 0).toInt(),
        suspended: (json['suspended'] ?? false) as bool,
      );
}
