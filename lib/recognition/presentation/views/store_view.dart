import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/store_bloc.dart';
import '../../application/bloc/wallet_bloc.dart';
import '../../domain/models/redeemable_benefit.dart';

// US32 · Tienda de beneficios: se canjea con SkillCredits tras confirmar con el dispositivo.
// Usa el WalletBloc de SkillCredits para el saldo, así que un canje lo refresca ahí también.
class StoreView extends StatelessWidget {
  const StoreView({super.key});

  Future<void> _confirm(BuildContext context, RedeemableBenefit benefit, int balance) async {
    final bloc = context.read<StoreBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Canjear ${benefit.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se descontarán ${benefit.cost} SkillCredits de tu saldo; te quedarán ${balance - benefit.cost}.'),
            if (benefit.confirmNote != null) ...[
              const SizedBox(height: 12),
              Text(benefit.confirmNote!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            const Text('Para continuar vamos a confirmar tu identidad con el dispositivo.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Canjear')),
        ],
      ),
    );
    if (confirmed == true) bloc.add(RedeemRequested(benefit));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Tienda de beneficios', style: text.headlineSmall)),
      body: BlocConsumer<StoreBloc, StoreState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
          switch (state) {
            case StoreRedeemed(:final benefit):
              messenger.showSnackBar(SnackBar(content: Text(benefit.successMessage)));
              context.read<WalletBloc>().add(const WalletRequested());
            case StoreFailed(:final message):
              messenger.showSnackBar(SnackBar(content: Text(message)));
            default:
              break;
          }
        },
        builder: (context, store) {
          final wallet = context.watch<WalletBloc>().state;
          void reload() => context.read<WalletBloc>().add(const WalletRequested());
          return switch (wallet) {
            WalletLoading() => const Center(child: CircularProgressIndicator()),
            WalletError(:final message) => MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudo cargar tu saldo',
                message: message,
                actionLabel: 'Reintentar',
                onAction: reload,
              ),
            WalletLoaded(:final balance, :final transactions) => RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    _BalanceHeader(balance),
                    const SizedBox(height: 16),
                    for (final benefit in RedeemableBenefit.values)
                      _BenefitCard(
                        benefit: benefit,
                        balance: balance,
                        alreadyRedeemed: benefit.oncePerUser && transactions.hasRedeemed(benefit),
                        busy: store is StoreRedeeming && store.benefit == benefit,
                        locked: store is StoreRedeeming,
                        onRedeem: () => _confirm(context, benefit, balance),
                      ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  final int balance;

  const _BalanceHeader(this.balance);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: Text('Tu saldo', style: text.titleSmall?.copyWith(color: Colors.white70))),
          Text('$balance', style: text.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(width: 6),
          Text('SkillCredits', style: text.bodyMedium?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final RedeemableBenefit benefit;
  final int balance;
  final bool alreadyRedeemed;
  final bool busy; // este beneficio se está canjeando
  final bool locked; // hay un canje en curso
  final VoidCallback onRedeem;

  const _BenefitCard({
    required this.benefit,
    required this.balance,
    required this.alreadyRedeemed,
    required this.busy,
    required this.locked,
    required this.onRedeem,
  });

  IconData get _icon => switch (benefit) {
        RedeemableBenefit.badge => Icons.military_tech_outlined,
        RedeemableBenefit.contributionCertificate => Icons.workspace_premium_outlined,
        RedeemableBenefit.advancedPathUnlock => Icons.alt_route,
        RedeemableBenefit.sponsoredCertification => Icons.verified_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final missing = benefit.cost - balance;
    final label = alreadyRedeemed
        ? 'Ya canjeada'
        : missing > 0
            ? 'Te faltan $missing SkillCredits'
            : 'Canjear';
    final enabled = !alreadyRedeemed && missing <= 0 && !locked;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.successContainer, borderRadius: BorderRadius.circular(12)),
                  child: Icon(_icon, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(benefit.title, style: text.titleSmall)),
                Text('${benefit.cost}', style: text.titleMedium),
                const SizedBox(width: 4),
                Text('SkillCredits', style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(benefit.description, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (busy)
              const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              FilledButton(onPressed: enabled ? onRedeem : null, child: Text(label)),
          ],
        ),
      ),
    );
  }
}
