import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/metrics_bloc.dart';
import '../../domain/models/platform_metrics.dart';

// T64 · Mock-up 29 "Métricas" (WF-41): demanda de habilidades, tasa de aprobación y mejores Verificadores.
class MetricsView extends StatelessWidget {
  const MetricsView({super.key});

  static const goal = 0.70; // meta de aprobación que marca la línea punteada

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Métricas', style: text.headlineSmall)),
      body: BlocBuilder<MetricsBloc, MetricsState>(
        builder: (context, state) {
          void reload() => context.read<MetricsBloc>().add(MetricsRequested(days: state.days));
          return switch (state) {
            MetricsInitial() || MetricsLoading() => const Center(child: CircularProgressIndicator()),
            MetricsForbidden() => const MessageView(
                icon: Icons.lock_outline,
                title: 'Solo para Verificadores senior',
                message: 'Las métricas de la plataforma las consulta un Verificador senior.',
              ),
            MetricsError(:final message) => MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudieron cargar las métricas',
                message: message,
                actionLabel: 'Reintentar',
                onAction: reload,
              ),
            final MetricsLoaded loaded => RefreshIndicator(
                onRefresh: () async => reload(),
                child: _MetricsContent(loaded),
              ),
          };
        },
      ),
    );
  }
}

class _MetricsContent extends StatelessWidget {
  final MetricsLoaded state;

  const _MetricsContent(this.state);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final skills = state.demand.topSkills.take(5).toList();
    final maxPaths = skills.isEmpty ? 1 : skills.map((s) => s.pathCount).reduce((a, b) => a > b ? a : b);
    final approval = state.difficulty.skills.take(5).toList();
    final best = state.verifiers.where((v) => !v.suspended).take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Align(alignment: Alignment.centerLeft, child: _PeriodSelector(days: state.days)),
        const SizedBox(height: 28),
        _SectionTitle('Habilidades más demandadas', 'Rutas por habilidad'),
        if (skills.isEmpty) const _Empty('Aún no hay rutas en este periodo.'),
        for (final s in skills)
          _BarRow(label: s.skillName, value: s.pathCount / maxPaths, trailing: '${s.pathCount}'),
        const SizedBox(height: 28),
        _SectionTitle(
          'Tasa de aprobación por habilidad',
          'Intentos de quiz aprobados · la línea punteada marca la meta de ${(MetricsView.goal * 100).round()}%',
        ),
        if (approval.isEmpty) const _Empty('Aún no hay suficientes intentos en este periodo.'),
        for (final s in approval)
          _BarRow(
            label: s.skillName,
            value: s.approvalRate,
            trailing: '${(s.approvalRate * 100).round()}%',
            goal: MetricsView.goal,
          ),
        const SizedBox(height: 28),
        Text('Verificadores con mejor desempeño', style: text.titleMedium),
        const SizedBox(height: 12),
        if (best.isEmpty)
          const _Empty('Todavía no hay Verificadores con casos resueltos.')
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < best.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                  _VerifierRow(position: i + 1, verifier: best[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final int days;

  const _PeriodSelector({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutralBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: days,
          icon: const Icon(Icons.expand_more),
          items: const [
            DropdownMenuItem(value: 7, child: _PeriodLabel('Últimos 7 días')),
            DropdownMenuItem(value: 30, child: _PeriodLabel('Últimos 30 días')),
            DropdownMenuItem(value: 90, child: _PeriodLabel('Últimos 90 días')),
          ],
          onChanged: (value) {
            if (value != null) context.read<MetricsBloc>().add(MetricsRequested(days: value));
          },
        ),
      ),
    );
  }
}

class _PeriodLabel extends StatelessWidget {
  final String label;

  const _PeriodLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// Una fila: nombre, barra (0 a 1) y valor; [goal] dibuja la línea punteada de la meta.
class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final String trailing;
  final double? goal;

  const _BarRow({required this.label, required this.value, required this.trailing, this.goal});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(label, style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: LayoutBuilder(
              builder: (context, box) => SizedBox(
                height: 14,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(color: AppColors.neutralSurface, borderRadius: BorderRadius.circular(4)),
                    ),
                    Container(
                      height: 8,
                      width: box.maxWidth * value.clamp(0, 1),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                    ),
                    if (goal != null)
                      Positioned(left: box.maxWidth * goal! - 1, top: 0, bottom: 0, child: const _DashedLine()),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(trailing, textAlign: TextAlign.right, style: text.titleSmall),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(width: 2, height: 2.5, margin: const EdgeInsets.only(bottom: 1), color: AppColors.textPrimary),
      ),
    );
  }
}

class _VerifierRow extends StatelessWidget {
  final int position;
  final VerifierMetric verifier;

  const _VerifierRow({required this.position, required this.verifier});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onTime = verifier.onTimePercent;
    final details = [
      'Confiabilidad ${verifier.score}/100',
      '${verifier.resolvedCasesCount} casos',
      if (onTime != null) '$onTime% dentro del plazo',
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: position == 1 ? AppColors.warningContainer : AppColors.neutralSurface,
        child: Text(
          '$position',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: position == 1 ? AppColors.warning : AppColors.textPrimary,
          ),
        ),
      ),
      title: Text(verifier.displayName, style: text.titleSmall),
      subtitle: Text(details, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;

  const _Empty(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
