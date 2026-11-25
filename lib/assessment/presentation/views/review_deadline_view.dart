import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/utils/formatters.dart';
import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/review_deadline_bloc.dart';
import '../../domain/models/review_deadline_policy.dart';

// US39 · Plazo de actividad: el senior define en cuánto se resuelven los casos del plan mensual y del gratuito.
class ReviewDeadlineView extends StatefulWidget {
  const ReviewDeadlineView({super.key});

  @override
  State<ReviewDeadlineView> createState() => _ReviewDeadlineViewState();
}

class _ReviewDeadlineViewState extends State<ReviewDeadlineView> {
  final _hours = TextEditingController();
  final _days = TextEditingController();

  @override
  void dispose() {
    _hours.dispose();
    _days.dispose();
    super.dispose();
  }

  // Los campos muestran el plazo vigente cada vez que llega una lista nueva (al cargar y al guardar).
  void _fill(ReviewDeadlineLoaded state) {
    _hours.text = '${state.premium?.amount ?? ''}';
    _days.text = '${state.free?.amount ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plazo de actividad')),
      body: BlocConsumer<ReviewDeadlineBloc, ReviewDeadlineState>(
        listenWhen: (previous, current) {
          if (current is! ReviewDeadlineLoaded) return false;
          if (previous is! ReviewDeadlineLoaded) return true;
          return !identical(previous.policies, current.policies) || current.notice != null || current.error != null;
        },
        listener: (context, state) {
          if (state is! ReviewDeadlineLoaded) return;
          // Un error no toca lo que el Verificador escribió; solo una lista nueva rellena los campos
          if (state.error == null) _fill(state);
          final message = state.notice ?? state.error;
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          void reload() => context.read<ReviewDeadlineBloc>().add(const ReviewDeadlinesRequested());
          return switch (state) {
            ReviewDeadlineLoading() => const Center(child: CircularProgressIndicator()),
            ReviewDeadlineError(:final message) => MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudo cargar el plazo',
                message: message,
                actionLabel: 'Reintentar',
                onAction: reload,
              ),
            final ReviewDeadlineLoaded loaded => _form(context, loaded),
          };
        },
      ),
    );
  }

  Widget _form(BuildContext context, ReviewDeadlineLoaded state) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          'Define en cuánto tiempo se resuelven los casos de cada plan. Aplica a los casos que se abran desde ahora; '
          'si un caso vence, pasa a otro Verificador.',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _PlanField(
          label: 'Plan mensual · horas',
          helper: 'De 1 a ${ReviewDeadlinePolicy.premiumMaxHours} horas',
          controller: _hours,
          policy: state.premium,
          enabled: !state.saving,
        ),
        const SizedBox(height: 20),
        _PlanField(
          label: 'Plan gratuito · días hábiles',
          helper: 'De 1 a ${ReviewDeadlinePolicy.freeMaxBusinessDays} días hábiles (lunes a viernes)',
          controller: _days,
          policy: state.free,
          enabled: !state.saving,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: state.saving
              ? null
              : () => context.read<ReviewDeadlineBloc>().add(
                    ReviewDeadlinesSaved(premiumHours: _hours.text, freeBusinessDays: _days.text),
                  ),
          child: state.saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar plazo'),
        ),
      ],
    );
  }
}

class _PlanField extends StatelessWidget {
  final String label;
  final String helper;
  final TextEditingController controller;
  final ReviewDeadlinePolicy? policy;
  final bool enabled;

  const _PlanField({
    required this.label,
    required this.helper,
    required this.controller,
    required this.policy,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = policy;
    final status = current == null
        ? null
        : current.definedBySenior
            ? 'Plazo vigente: ${current.amountLabel} · definido por un Verificador senior el ${shortDate(current.updatedAt)}'
            : 'Plazo vigente: ${current.amountLabel} · el que trae el plan por defecto';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          decoration: InputDecoration(labelText: label, helperText: helper),
        ),
        if (status != null) ...[
          const SizedBox(height: 4),
          Text(status, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ],
    );
  }
}
