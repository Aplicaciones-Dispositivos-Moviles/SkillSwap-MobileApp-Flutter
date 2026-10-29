import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/components/status_chip.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/supervision_bloc.dart';
import '../../domain/models/platform_metrics.dart';
import '../../domain/models/verifier_reliability.dart';

// T62 · Supervisión de Verificadores (US38): suspender a quien tiene baja confiabilidad o reactivarlo.
class SupervisionView extends StatelessWidget {
  const SupervisionView({super.key});

  Future<void> _suspend(BuildContext context, VerifierMetric verifier) async {
    final bloc = context.read<SupervisionBloc>();
    final justification = await showDialog<String>(
      context: context,
      builder: (_) => _SuspendDialog(name: verifier.displayName),
    );
    if (justification != null) bloc.add(VerifierSuspended(verifier.verifierUserId, justification));
  }

  Future<void> _reinstate(BuildContext context, VerifierMetric verifier) async {
    final bloc = context.read<SupervisionBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reactivar a ${verifier.displayName}'),
        content: const Text('Volverá a recibir casos nuevos.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Reactivar')),
        ],
      ),
    );
    if (confirmed == true) bloc.add(VerifierReinstated(verifier.verifierUserId));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Supervisar Verificadores')),
      body: BlocConsumer<SupervisionBloc, SupervisionState>(
        listenWhen: (previous, current) =>
            current is SupervisionLoaded && (current.notice != null || current.error != null),
        listener: (context, state) {
          if (state is SupervisionLoaded) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.notice ?? state.error!)));
          }
        },
        builder: (context, state) {
          void reload() => context.read<SupervisionBloc>().add(const SupervisionRequested());
          return switch (state) {
            SupervisionLoading() => const Center(child: CircularProgressIndicator()),
            SupervisionForbidden() => const MessageView(
                icon: Icons.lock_outline,
                title: 'Solo para Verificadores senior',
                message: 'La supervisión de Verificadores la hace un Verificador senior.',
              ),
            SupervisionError(:final message) => MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudo cargar a los Verificadores',
                message: message,
                actionLabel: 'Reintentar',
                onAction: reload,
              ),
            final SupervisionLoaded loaded => RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Text(
                      'Ordenados de menor a mayor confiabilidad. Solo se puede suspender a quien tiene menos de '
                      '${VerifierMetric.suspensionThreshold}/100.',
                      style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    if (loaded.verifiers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Todavía no hay otros Verificadores.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    for (final v in loaded.verifiers)
                      _VerifierTile(
                        verifier: v,
                        busy: loaded.busyUserId == v.verifierUserId,
                        locked: loaded.busyUserId != null,
                        onSuspend: () => _suspend(context, v),
                        onReinstate: () => _reinstate(context, v),
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

class _VerifierTile extends StatelessWidget {
  final VerifierMetric verifier;
  final bool busy; // este Verificador se está guardando
  final bool locked; // hay otro guardado en curso
  final VoidCallback onSuspend;
  final VoidCallback onReinstate;

  const _VerifierTile({
    required this.verifier,
    required this.busy,
    required this.locked,
    required this.onSuspend,
    required this.onReinstate,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onTime = verifier.onTimePercent;
    final details = [
      'Confiabilidad ${verifier.score}/100',
      'Rango ${rankName(verifier.rank)}',
      '${verifier.resolvedCasesCount} casos',
      if (onTime != null) '$onTime% dentro del plazo',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(verifier.displayName, style: text.titleSmall)),
                if (verifier.suspended)
                  const StatusChip(
                    'Suspendido',
                    color: AppColors.error,
                    container: AppColors.errorContainer,
                    icon: Icons.block,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(details, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (busy)
              const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else if (verifier.suspended)
              OutlinedButton(onPressed: locked ? null : onReinstate, child: const Text('Reactivar'))
            else if (verifier.canBeSuspended)
              OutlinedButton(
                onPressed: locked ? null : onSuspend,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Suspender'),
              )
            else
              Text(
                'No se puede suspender: su confiabilidad es de ${VerifierMetric.suspensionThreshold} o más.',
                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

// Pide la justificación obligatoria de la suspensión (máximo 2000 caracteres).
class _SuspendDialog extends StatefulWidget {
  final String name;

  const _SuspendDialog({required this.name});

  @override
  State<_SuspendDialog> createState() => _SuspendDialogState();
}

class _SuspendDialogState extends State<_SuspendDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Escribe la justificación');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Suspender a ${widget.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dejará de recibir casos nuevos hasta que lo reactives.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: VerifierMetric.justificationMaxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Justificación', errorText: _error),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Suspender'),
        ),
      ],
    );
  }
}
