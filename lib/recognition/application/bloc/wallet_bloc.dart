import 'package:bloc/bloc.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/wallet.dart';
import '../../domain/repositories/recognition_repository.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

// Billetera de SkillCredits del Verificador (US31, mock-up 25), punto de entrada para compartir el logro.
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final int userId;
  final RecognitionRepository recognitionRepository;

  WalletBloc({required this.userId, required this.recognitionRepository}) : super(const WalletLoading()) {
    on<WalletRequested>(_onRequested);
  }

  Future<void> _onRequested(WalletRequested event, Emitter<WalletState> emit) async {
    if (state is! WalletLoaded) emit(const WalletLoading());
    try {
      final wallet = await recognitionRepository.getWallet(userId);
      final transactions = await recognitionRepository.getTransactions(userId);
      emit(WalletLoaded(balance: wallet?.balance ?? 0, transactions: transactions));
    } catch (e) {
      emit(WalletError(ApiException.from(e, 'No se pudo cargar tu billetera').message));
    }
  }
}
