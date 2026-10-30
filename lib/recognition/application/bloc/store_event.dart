part of 'store_bloc.dart';

sealed class StoreEvent {
  const StoreEvent();
}

// La persona confirmó el canje en pantalla; falta la confirmación con el dispositivo y el POST.
class RedeemRequested extends StoreEvent {
  final RedeemableBenefit benefit;

  const RedeemRequested(this.benefit);
}
