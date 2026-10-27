part of 'wallet_bloc.dart';

sealed class WalletState {
  const WalletState();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final int balance;
  final List<CreditTransaction> transactions;

  const WalletLoaded({required this.balance, required this.transactions});
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);
}
