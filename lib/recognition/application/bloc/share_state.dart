part of 'share_bloc.dart';

sealed class ShareState {
  const ShareState();
}

class ShareLoading extends ShareState {
  const ShareLoading();
}

// Mock-up 26e1: todavía no tiene habilidades verificadas que compartir
class ShareNoCredential extends ShareState {
  const ShareNoCredential();
}

class ShareReady extends ShareState {
  final List<String> skillTags;
  final String selectedTag;
  final ShareableCredential? credential; // null mientras se genera el enlace
  final bool generating;
  final String? rank; // Bronce | Plata | Oro
  final int reviewCount;
  final double rating;
  final int balance;
  final String? error;

  const ShareReady({
    required this.skillTags,
    required this.selectedTag,
    required this.credential,
    required this.generating,
    required this.rank,
    required this.reviewCount,
    required this.rating,
    required this.balance,
    this.error,
  });

  ShareReady copyWith({String? selectedTag, ShareableCredential? credential, bool clearCredential = false, bool? generating, String? error}) {
    return ShareReady(
      skillTags: skillTags,
      selectedTag: selectedTag ?? this.selectedTag,
      credential: clearCredential ? null : (credential ?? this.credential),
      generating: generating ?? this.generating,
      rank: rank,
      reviewCount: reviewCount,
      rating: rating,
      balance: balance,
      error: error,
    );
  }
}

class ShareError extends ShareState {
  final String message;

  const ShareError(this.message);
}
