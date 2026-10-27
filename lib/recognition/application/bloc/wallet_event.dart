part of 'wallet_bloc.dart';

sealed class WalletEvent {
  const WalletEvent();
}

class WalletRequested extends WalletEvent {
  const WalletRequested();
}
