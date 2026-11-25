import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../service_locator.dart';
import '../../../shared/domain/utils/formatters.dart';
import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/components/status_chip.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/dispute_detail_bloc.dart';
import '../../application/bloc/disputes_bloc.dart';
import '../../domain/models/dispute.dart';
import 'dispute_detail_view.dart';

// US34 · Disputas asignadas al Verificador: los certificados sospechosos que debe revisar, de la más antigua a la más reciente.
class DisputesView extends StatelessWidget {
  const DisputesView({super.key});

  // US35 · Abre el certificado en revisión; si se resolvió, la lista se recarga
  Future<void> _open(BuildContext context, Dispute dispute, {required bool resolved}) async {
    final bloc = context.read<DisputesBloc>();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<DisputeDetailBloc>()..add(DisputeEvidenceRequested(dispute.id)),
          child: const DisputeDetailView(),
        ),
      ),
    );
    if (changed == true) bloc.add(DisputesRequested(resolved: resolved));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Disputas pendientes')),
      body: BlocBuilder<DisputesBloc, DisputesState>(
        builder: (context, state) {
          final resolved = state is DisputesLoaded && state.resolved;
          void load({bool? showResolved}) =>
              context.read<DisputesBloc>().add(DisputesRequested(resolved: showResolved ?? resolved));
          return switch (state) {
            DisputesLoading() => const Center(child: CircularProgressIndicator()),
            DisputesForbidden() => const MessageView(
                icon: Icons.lock_outline,
                title: 'Solo para Verificadores habilitados',
                message: 'Las disputas las revisa un Verificador habilitado.',
              ),
            DisputesError(:final message) => MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudieron cargar las disputas',
                message: message,
                actionLabel: 'Reintentar',
                onAction: load,
              ),
            final DisputesLoaded loaded => RefreshIndicator(
                onRefresh: () async => load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Text(
                      'Certificados sospechosos que te tocan decidir. La revisión es ciega: no ves de quién es el certificado.',
                      style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Pendientes')),
                        ButtonSegment(value: true, label: Text('Resueltas')),
                      ],
                      selected: {loaded.resolved},
                      onSelectionChanged: (value) => load(showResolved: value.first),
                    ),
                    const SizedBox(height: 16),
                    if (loaded.disputes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          loaded.resolved ? 'Todavía no resolviste ninguna disputa.' : 'No tienes disputas pendientes.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    for (final d in loaded.disputes)
                      _DisputeTile(d, onTap: () => _open(context, d, resolved: loaded.resolved)),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

class _DisputeTile extends StatelessWidget {
  final Dispute dispute;
  final VoidCallback onTap;

  const _DisputeTile(this.dispute, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final outcome = dispute.outcomeLabel;
    final upheld = dispute.outcome == 'Upheld';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('${dispute.sourceLabel} #${dispute.sourceReferenceId}', style: text.titleSmall)),
                  if (outcome != null)
                    StatusChip(
                      outcome,
                      color: upheld ? AppColors.success : AppColors.error,
                      container: upheld ? AppColors.successContainer : AppColors.errorContainer,
                      icon: upheld ? Icons.verified_outlined : Icons.block_outlined,
                    )
                  else
                    const StatusChip(
                      'Pendiente',
                      color: AppColors.warning,
                      container: AppColors.warningContainer,
                      icon: Icons.schedule,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dispute.isPending
                    ? 'Abierta el ${shortDate(dispute.raisedAt)}'
                    : 'Resuelta el ${shortDate(dispute.resolvedAt)}',
                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text('Por qué es sospechoso', style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              for (final reason in dispute.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3, right: 8),
                        child: Icon(Icons.flag_outlined, size: 14, color: AppColors.warning),
                      ),
                      Expanded(child: Text(reason, style: text.bodyMedium)),
                    ],
                  ),
                ),
              if (!dispute.isPending && (dispute.resolutionNotes ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tus observaciones', style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(dispute.resolutionNotes!, style: text.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
