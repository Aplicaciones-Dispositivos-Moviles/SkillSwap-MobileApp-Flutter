import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../service_locator.dart';
import '../../../shared/domain/utils/formatters.dart';
import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/share_bloc.dart';
import '../../application/bloc/store_bloc.dart';
import '../../application/bloc/wallet_bloc.dart';
import '../../domain/models/wallet.dart';
import 'share_achievement_view.dart';
import 'store_view.dart';

// Mock-up 25 "SkillCredits" (WF-24 #01): saldo, movimientos y acceso a compartir el logro (T58).
class SkillCreditsView extends StatelessWidget {
  const SkillCreditsView({super.key});

  void _share(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider(
          create: (_) => getIt<ShareBloc>()..add(const ShareRequested()),
          child: const ShareAchievementView(),
        ),
      ),
    );
  }

  // US32 · Tienda de beneficios: comparte el WalletBloc para ver y refrescar el saldo
  void _openStore(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<WalletBloc>()),
            BlocProvider(create: (_) => getIt<StoreBloc>()),
          ],
          child: const StoreView(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('SkillCredits', style: text.headlineSmall)),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          void reload() => context.read<WalletBloc>().add(const WalletRequested());
          return switch (state) {
            WalletLoading() => const Center(child: CircularProgressIndicator()),
            WalletError(:final message) => MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudo cargar tu billetera',
                message: message,
                actionLabel: 'Reintentar',
                onAction: reload,
              ),
            WalletLoaded(:final balance, :final transactions) => RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    _BalanceCard(balance: balance, onShare: () => _share(context), onStore: () => _openStore(context)),
                    const SizedBox(height: 24),
                    Text('Movimientos', style: text.titleMedium),
                    const SizedBox(height: 8),
                    if (transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Todavía no tienes movimientos. Ganas SkillCredits al resolver casos.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    for (final t in transactions) _TransactionTile(t),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int balance;
  final VoidCallback onShare;
  final VoidCallback onStore;

  const _BalanceCard({required this.balance, required this.onShare, required this.onStore});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SALDO DISPONIBLE', style: text.labelMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$balance', style: text.headlineMedium?.copyWith(color: Colors.white)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('SkillCredits', style: text.bodyMedium?.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: onShare,
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Compartir logro'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: onStore,
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Tienda de beneficios'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final CreditTransaction transaction;

  const _TransactionTile(this.transaction);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final positive = transaction.amount >= 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: positive ? AppColors.successContainer : AppColors.errorContainer,
        child: Icon(positive ? Icons.arrow_upward : Icons.arrow_downward,
            color: positive ? AppColors.success : AppColors.error, size: 18),
      ),
      title: Text(transaction.title, style: text.titleSmall),
      subtitle: Text(shortDate(transaction.createdAt), style: text.bodySmall),
      trailing: Text(
        '${positive ? '+' : ''}${transaction.amount}',
        style: text.titleSmall?.copyWith(color: positive ? AppColors.success : AppColors.error),
      ),
    );
  }
}
