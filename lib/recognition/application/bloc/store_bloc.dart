import 'package:bloc/bloc.dart';

import '../../../shared/domain/services/device_authenticator.dart';
import '../../../shared/domain/utils/idempotency_key.dart';
import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/redeemable_benefit.dart';
import '../../domain/models/wallet.dart';
import '../../domain/repositories/recognition_repository.dart';

part 'store_event.dart';
part 'store_state.dart';

// US32 · Canje de SkillCredits en la tienda: primero confirma con el dispositivo y luego llama al backend.
class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final RecognitionRepository recognitionRepository;
  final DeviceAuthenticator deviceAuthenticator;
  final String Function() newIdempotencyKey;

  // Key of a redeem whose outcome is unknown (no response or 5xx), reused if the same benefit is retried
  ({String item, String key})? _pending;

  StoreBloc({
    required this.recognitionRepository,
    required this.deviceAuthenticator,
    String Function()? newIdempotencyKey,
  })  : newIdempotencyKey = newIdempotencyKey ?? generateIdempotencyKey,
        super(const StoreIdle()) {
    on<RedeemRequested>(_onRedeem);
  }

  Future<void> _onRedeem(RedeemRequested event, Emitter<StoreState> emit) async {
    if (state is StoreRedeeming) return;
    final benefit = event.benefit;
    emit(StoreRedeeming(benefit));

    // El servidor no verifica la biometría, así que se confirma aquí antes de llamar al endpoint
    final DeviceAuthResult auth;
    try {
      auth = await deviceAuthenticator.confirm('Confirma tu identidad para canjear ${benefit.title}');
    } catch (_) {
      emit(const StoreFailed('No se pudo confirmar tu identidad. Inténtalo de nuevo.'));
      return;
    }
    switch (auth) {
      case DeviceAuthResult.unavailable:
        emit(const StoreFailed('Configura un bloqueo de pantalla (huella, PIN o patrón) en tu dispositivo para canjear.'));
        return;
      case DeviceAuthResult.cancelled:
        emit(const StoreFailed('No se confirmó tu identidad, así que no se hizo el canje.'));
        return;
      case DeviceAuthResult.confirmed:
        break;
    }

    final item = benefit.apiValue;
    final pending = _pending;
    final key = pending != null && pending.item == item ? pending.key : newIdempotencyKey();
    _pending = (item: item, key: key);
    try {
      final transaction = await recognitionRepository.redeem(item, idempotencyKey: key);
      _pending = null;
      emit(StoreRedeemed(benefit, transaction));
    } catch (e) {
      final error = ApiException.from(e, 'No se pudo canjear el beneficio');
      // A 4xx is a definitive answer; without a response or with a 5xx the debit may have happened
      final status = error.status;
      if (status != null && status < 500) _pending = null;
      emit(StoreFailed(error.message));
    }
  }
}
