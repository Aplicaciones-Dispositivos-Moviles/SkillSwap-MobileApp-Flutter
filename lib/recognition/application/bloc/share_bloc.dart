import 'package:bloc/bloc.dart';

import '../../../assessment/domain/repositories/verification_case_repository.dart';
import '../../../reputation/domain/repositories/reputation_repository.dart';
import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/shareable_credential.dart';
import '../../domain/repositories/recognition_repository.dart';

part 'share_event.dart';
part 'share_state.dart';

// T58 · Compartir el logro en LinkedIn u otras redes (US33, mock-up 26).
// El texto y el enlace los genera el backend (T57); la app arma la vista previa y abre el menú de compartir.
class ShareBloc extends Bloc<ShareEvent, ShareState> {
  final int userId;
  final RecognitionRepository recognitionRepository;
  final VerificationCaseRepository caseRepository;
  final ReputationRepository reputationRepository;

  // Enlaces ya generados en esta pantalla, por habilidad
  final Map<String, ShareableCredential> _cache = {};

  ShareBloc({
    required this.userId,
    required this.recognitionRepository,
    required this.caseRepository,
    required this.reputationRepository,
  }) : super(const ShareLoading()) {
    on<ShareRequested>(_onRequested);
    on<ShareSkillSelected>(_onSkillSelected);
  }

  Future<void> _onRequested(ShareRequested event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final profile = await caseRepository.getMyProfile();
      if (profile == null || profile.skillTags.isEmpty) {
        emit(const ShareNoCredential());
        return;
      }
      for (final c in await recognitionRepository.getShareableCredentials()) {
        _cache[c.skillTag] = c;
      }
      String? rank;
      int balance = 0;
      try {
        rank = (await reputationRepository.getReliability(userId))?.rankLabel;
      } catch (_) {}
      try {
        balance = (await recognitionRepository.getWallet(userId))?.balance ?? 0;
      } catch (_) {}
      final first = profile.skillTags.first;
      emit(ShareReady(
        skillTags: profile.skillTags,
        selectedTag: first,
        credential: _cache[first],
        generating: false,
        rank: rank,
        reviewCount: profile.reviewCount,
        rating: profile.rating,
        balance: balance,
      ));
      if (_cache[first] == null) add(ShareSkillSelected(first));
    } catch (e) {
      emit(ShareError(ApiException.from(e, 'No se pudo preparar tu credencial').message));
    }
  }

  Future<void> _onSkillSelected(ShareSkillSelected event, Emitter<ShareState> emit) async {
    final current = state;
    if (current is! ShareReady) return;
    final cached = _cache[event.skillTag];
    if (cached != null) {
      emit(current.copyWith(selectedTag: event.skillTag, credential: cached, generating: false));
      return;
    }
    emit(current.copyWith(selectedTag: event.skillTag, clearCredential: true, generating: true));
    try {
      final credential = await recognitionRepository.createShareableCredential(event.skillTag);
      _cache[event.skillTag] = credential;
      final latest = state;
      if (latest is ShareReady && latest.selectedTag == event.skillTag) {
        emit(latest.copyWith(credential: credential, generating: false));
      }
    } catch (e) {
      final latest = state;
      if (latest is ShareReady) {
        emit(latest.copyWith(generating: false, error: ApiException.from(e, 'No se pudo generar el enlace').message));
      }
    }
  }
}
