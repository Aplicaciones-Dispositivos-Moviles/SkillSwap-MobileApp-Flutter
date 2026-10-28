import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../iam/application/bloc/session_bloc.dart';
import '../../../service_locator.dart';
import '../../../shared/domain/utils/formatters.dart';
import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/components/status_chip.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/case_review_bloc.dart';
import '../../application/bloc/cases_bloc.dart';
import '../../domain/models/verification_case.dart';
import 'availability_view.dart';
import 'case_review_view.dart';

// T71 · Mock-up 13 "Inicio del Verificador": disponibilidad, resumen y casos asignados.
class CasesView extends StatelessWidget {
  const CasesView({super.key});

  Future<void> _open(BuildContext context, VerificationCase item) async {
    final bloc = context.read<CasesBloc>();
    final resolved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<CaseReviewBloc>()..add(CaseReviewRequested(item.id)),
          child: const CaseReviewView(),
        ),
      ),
    );
    // Al resolver un caso se recargan la lista, el saldo y la confiabilidad
    if (resolved == true) bloc.add(const CasesRequested());
  }

  void _openAvailability(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: context.read<CasesBloc>(), child: const AvailabilityView()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;
    final username = session is Authenticated ? session.user.username : '';
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: BlocBuilder<CasesBloc, CasesState>(
          builder: (context, state) {
            final rank = state is CasesLoaded ? state.reliability?.rankLabel : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $username', style: text.titleLarge),
                Text(
                  rank == null ? 'Verificador' : 'Verificador · Rango $rank',
                  style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SessionBloc>().add(const SignOutRequested()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<CasesBloc, CasesState>(
        builder: (context, state) {
          void reload() => context.read<CasesBloc>().add(const CasesRequested());
          return switch (state) {
            CasesInitial() || CasesLoading() => const Center(child: CircularProgressIndicator()),
            NotAVerifier() => MessageView(
                icon: Icons.verified_user_outlined,
                title: 'Aún no eres Verificador',
                message: 'Completa un nodo de tu ruta en la app del Estudiante y habilítate como Verificador '
                    'de esa habilidad para recibir casos.',
                actionLabel: 'Volver a revisar',
                onAction: reload,
              ),
            CasesError(:final message) => MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudieron cargar tus casos',
                message: message,
                actionLabel: 'Reintentar',
                onAction: reload,
              ),
            final CasesLoaded loaded => RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    _AvailabilityCard(loaded, onTap: () => _openAvailability(context)),
                    const SizedBox(height: 16),
                    _SummaryRow(loaded),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Text('Casos asignados', style: text.titleMedium)),
                        Text(
                          '${loaded.pending.length} pendientes',
                          style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (loaded.cases.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No tienes casos asignados por ahora. Te avisaremos cuando llegue uno.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    for (final c in loaded.cases) _CaseCard(item: c, onTap: () => _open(context, c)),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

// Disponibilidad y habilidades que revisa; al tocarla se abre la pantalla de disponibilidad (T72)
class _AvailabilityCard extends StatelessWidget {
  final CasesLoaded state;
  final VoidCallback onTap;

  const _AvailabilityCard(this.state, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final profile = state.profile;
    final (label, color, container, icon) = profile.suspended
        ? ('Suspendido', AppColors.error, AppColors.errorContainer, Icons.block)
        : profile.available
            ? ('Disponible para casos', AppColors.success, AppColors.successContainer, Icons.check_circle)
            : ('En pausa', AppColors.warning, AppColors.warningContainer, Icons.pause_circle);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: container, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.titleSmall),
                    Text(
                      profile.skillTags.map(skillLabel).join(' · '),
                      style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final CasesLoaded state;

  const _SummaryRow(this.state);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(icon: Icons.toll, color: AppColors.warning, value: '${state.balance ?? 0}', label: 'SkillCredits')),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(
            icon: Icons.star_rounded,
            color: AppColors.warning,
            value: state.reliability == null ? '—' : '${state.reliability!.score}',
            label: 'Confiabilidad',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(
            icon: Icons.check_circle,
            color: AppColors.success,
            value: '${state.profile.reviewCount}',
            label: 'Resueltos',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: text.titleLarge),
            Text(label, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final VerificationCase item;
  final VoidCallback onTap;

  const _CaseCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final due = item.isResolved ? null : dueLabel(item.reviewDueAt);
    final overdue = due == 'Vencido';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (item.isResolved)
                          StatusChip(
                            item.decision == 'Approved' ? 'Aprobado' : 'Rechazado',
                            icon: item.decision == 'Approved' ? Icons.check : Icons.close,
                            color: item.decision == 'Approved' ? AppColors.success : AppColors.error,
                            container: item.decision == 'Approved' ? AppColors.successContainer : AppColors.errorContainer,
                          )
                        else if (due != null)
                          StatusChip(
                            due,
                            icon: Icons.schedule,
                            color: overdue ? AppColors.error : AppColors.warning,
                            container: overdue ? AppColors.errorContainer : AppColors.warningContainer,
                          ),
                        StatusChip(item.typeLabel, color: AppColors.textPrimary, container: AppColors.neutralSurface),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(skillLabel(item.skillTag), style: text.titleMedium),
                    Text(
                      '${item.code} · Estudiante anónimo',
                      style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
