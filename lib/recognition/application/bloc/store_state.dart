part of 'store_bloc.dart';

sealed class StoreState {
  const StoreState();
}

class StoreIdle extends StoreState {
  const StoreIdle();
}

class StoreRedeeming extends StoreState {
  final RedeemableBenefit benefit;

  const StoreRedeeming(this.benefit);
}

// Canje hecho: la vista muestra el aviso y refresca la billetera.
class StoreRedeemed extends StoreState {
  final RedeemableBenefit benefit;
  final CreditTransaction transaction;

  const StoreRedeemed(this.benefit, this.transaction);
}

class StoreFailed extends StoreState {
  final String message;

  const StoreFailed(this.message);
}
