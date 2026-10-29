import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/utils/formatters.dart';
import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/reevaluation_bloc.dart';
import '../../domain/models/reevaluation_candidate.dart';

// T60 · Reevaluación de un resultado aprobado (US37): el senior ordena que el Estudiante demuestre la habilidad otra vez.
class ReevaluationView extends StatelessWidget {
  const ReevaluationView({super.key});

  Future<void> _order(BuildContext context, ReevaluationCandidate candidate) async {
    final bloc = context.read<ReevaluationBloc>();
    final justification = await showDialog<String>(
      context: context,
      builder: (_) => _JustificationDialog(skill: skillLabel(candidate.skillTag)),
    );
    if (justification != null) bloc.add(ReevaluationOrdered(candidate, justification));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Reevaluar resultados')),
      body: BlocConsumer<ReevaluationBloc, ReevaluationState>(
        listenWhen: (previous, current) =>
            current is ReevaluationLoaded && (current.notice != null || current.error != null),
        listener: (context, state) {
          if (state is ReevaluationLoaded) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.notice ?? state.error!)));
          }
        },
        builder: (context, state) {
          void reload() => context.read<ReevaluationBloc>().add(const ReevaluationsRequested());
          return switch (state) {
            ReevaluationLoading() => const Center(child: CircularProgressIndicator()),
            ReevaluationForbidden() => const MessageView(
                icon: Icons.lock_outline,
                title: 'Solo para Verificadores senior',
                message: 'La reevaluación de resultados la ordena un Verificador senior.',
              ),
            ReevaluationError(:final message) => MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudieron cargar los resultados',
                message: message,
                actionLabel: 'Reintentar',
                onAction: reload,
              ),
            final ReevaluationLoaded loaded => RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Text(
                      'Resultados aprobados de otros Estudiantes, del más reciente al más antiguo. '
                      'Si dudas de uno, el Estudiante tendrá que demostrar la habilidad de nuevo.',
                      style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    if (loaded.candidates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No hay resultados para reevaluar por ahora.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    for (final c in loaded.candidates)
                      _CandidateTile(
                        candidate: c,
                        busy: loaded.busyKey == c.key,
                        locked: loaded.busyKey != null,
                        onOrder: () => _order(context, c),
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

class _CandidateTile extends StatelessWidget {
  final ReevaluationCandidate candidate;
  final bool busy; // este resultado se está enviando
  final bool locked; // hay otro envío en curso
  final VoidCallback onOrder;

  const _CandidateTile({
    required this.candidate,
    required this.busy,
    required this.locked,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final details = [
      candidate.kindLabel,
      if (candidate.resolvedAt != null) shortDate(candidate.resolvedAt),
      if (candidate.approvedByName != null && candidate.approvedByName!.isNotEmpty)
        'Aprobó ${candidate.approvedByName}',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(skillLabel(candidate.skillTag), style: text.titleSmall),
            const SizedBox(height: 4),
            Text(details, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (busy)
              const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              OutlinedButton(onPressed: locked ? null : onOrder, child: const Text('Ordenar reevaluación')),
          ],
        ),
      ),
    );
  }
}

// Pide la justificación obligatoria de la reevaluación (máximo 2000 caracteres).
class _JustificationDialog extends StatefulWidget {
  final String skill;

  const _JustificationDialog({required this.skill});

  @override
  State<_JustificationDialog> createState() => _JustificationDialogState();
}

class _JustificationDialogState extends State<_JustificationDialog> {
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
      title: Text('Reevaluar ${widget.skill}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('El Estudiante tendrá que demostrar la habilidad de nuevo. Cuéntanos por qué dudas del resultado.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: ReevaluationCandidate.justificationMaxLength,
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
        FilledButton(onPressed: _submit, child: const Text('Ordenar')),
      ],
    );
  }
}
