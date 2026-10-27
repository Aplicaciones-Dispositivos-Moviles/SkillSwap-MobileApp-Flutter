import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/domain/utils/formatters.dart';
import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/components/status_chip.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/case_review_bloc.dart';
import '../../domain/models/rubric.dart';
import '../../domain/models/verification_case.dart';

// T71 · Mock-up 14 "Detalle del caso" (WF-11): evidencia, intento, rúbrica y decisión del Verificador.
class CaseReviewView extends StatefulWidget {
  const CaseReviewView({super.key});

  @override
  State<CaseReviewView> createState() => _CaseReviewViewState();
}

class _CaseReviewViewState extends State<CaseReviewView> {
  final Map<String, RubricLevel> _levels = {};
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _decide(List<RubricCriterion> criteria, {required bool approve}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? '¿Aprobar este caso?' : '¿Rechazar este caso?'),
        content: Text(
          approve
              ? 'El nodo del Estudiante quedará completado.'
              : 'El Estudiante verá tus notas de la rúbrica y podrá apelar una vez.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(approve ? 'Aprobar' : 'Rechazar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<CaseReviewBloc>().add(
          CaseDecisionSubmitted(approve: approve, rubricNotes: buildRubricNotes(criteria, _levels, _comment.text)),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CaseReviewBloc, CaseReviewState>(
      listener: (context, state) async {
        if (state is CaseReviewLoaded && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
        if (state is CaseResolved) {
          final approved = state.resolved.decision == 'Approved';
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              icon: Icon(
                approved ? Icons.check_circle : Icons.cancel,
                color: approved ? AppColors.success : AppColors.error,
                size: 40,
              ),
              title: Text(approved ? 'Caso aprobado' : 'Caso rechazado'),
              content: const Text('Registramos tu decisión. Los SkillCredits del caso se acreditan en tu billetera.'),
              actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Entendido'))],
            ),
          );
          if (context.mounted) Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return switch (state) {
          CaseReviewLoading() => const Scaffold(body: Center(child: CircularProgressIndicator())),
          CaseReviewError(:final message) => Scaffold(
              appBar: AppBar(),
              body: MessageView(icon: Icons.error_outline, title: 'No se pudo abrir el caso', message: message),
            ),
          CaseReviewLoaded(:final detail, :final submitting) => _content(context, detail, submitting: submitting),
          CaseResolved(:final detail) => _content(context, detail, submitting: true),
        };
      },
    );
  }

  Widget _content(BuildContext context, CaseDetail detail, {required bool submitting}) {
    final text = Theme.of(context).textTheme;
    final item = detail.verificationCase;
    final criteria = rubricFor(miniProject: item.isMiniProject);
    final rated = criteria.where((c) => _levels[c.name] != null).length;
    final canDecide = !item.isResolved && !submitting && rated == criteria.length;
    final due = item.isResolved ? null : dueLabel(item.reviewDueAt);

    return Scaffold(
      appBar: AppBar(
        title: Text('Caso ${item.code}'),
        actions: [
          if (due != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StatusChip(due, icon: Icons.schedule, color: AppColors.error, container: AppColors.errorContainer),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(skillLabel(item.skillTag), style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${item.typeLabel} · ${skillLabel(item.skillTag)}${item.isAppeal ? ' · Apelado por el Estudiante' : ''}',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _EvidenceCard(item: item, attempt: detail.attempt),
          if (detail.failedQuestions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Preguntas que falló', style: text.titleMedium),
            const SizedBox(height: 8),
            for (final q in detail.failedQuestions) _FailedQuestionTile(q),
          ],
          const SizedBox(height: 24),
          if (item.isResolved)
            _ResolvedNotes(item)
          else ...[
            Row(
              children: [
                Expanded(child: Text('Rúbrica de evaluación', style: text.titleMedium)),
                Text(
                  '$rated de ${criteria.length} calificados',
                  style: text.bodySmall?.copyWith(
                    color: rated == criteria.length ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final c in criteria)
              _CriterionCard(
                criterion: c,
                level: _levels[c.name],
                enabled: !submitting,
                onChanged: (level) => setState(() => _levels[c.name] = level),
              ),
            const SizedBox(height: 8),
            Text('Comentario para el Estudiante', style: text.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              enabled: !submitting,
              minLines: 3,
              maxLines: 6,
              maxLength: 600,
              decoration: const InputDecoration(hintText: 'Qué hizo bien y qué debe reforzar'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: item.isResolved
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (rated == criteria.length)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          suggestsApproval(_levels)
                              ? 'Según la rúbrica, el caso cumple para aprobarse.'
                              : 'Según la rúbrica, hay criterios por debajo de lo esperado.',
                          style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            onPressed: canDecide ? () => _decide(criteria, approve: false) : null,
                            child: const Text('Rechazar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: canDecide ? () => _decide(criteria, approve: true) : null,
                            child: Text(submitting ? 'Enviando…' : 'Aprobar caso'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Evidencia del Estudiante y lo que obtuvo en el intento (la IA no pudo cerrar el caso sola)
class _EvidenceCard extends StatelessWidget {
  final VerificationCase item;
  final CaseAttempt? attempt;

  const _EvidenceCard({required this.item, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final url = item.evidenceUrl;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EVIDENCIA DEL ESTUDIANTE', style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            if (url == null || url.isEmpty)
              Text('El Estudiante no adjuntó un enlace.', style: text.bodyMedium)
            else
              InkWell(
                onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        url.replaceFirst(RegExp(r'^https?://'), ''),
                        style: text.bodyMedium?.copyWith(color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            if (attempt != null) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.aiViolet, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Obtuvo ${attempt!.score}/${attempt!.totalQuestions} en el quiz'
                      '${attempt!.weakSubTopic == null ? '' : '; su sub-tema más débil es "${attempt!.weakSubTopic}"'}'
                      '. Por eso el caso requiere tu revisión.',
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FailedQuestionTile extends StatelessWidget {
  final FailedQuestion question;

  const _FailedQuestionTile(this.question);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${question.position}. ${question.question}', style: text.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Respondió: ${question.selectedText ?? '—'}',
              style: text.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}

// Un criterio con sus cuatro niveles (Insuficiente, Básico, Bueno, Excelente)
class _CriterionCard extends StatelessWidget {
  final RubricCriterion criterion;
  final RubricLevel? level;
  final bool enabled;
  final ValueChanged<RubricLevel> onChanged;

  const _CriterionCard({required this.criterion, required this.level, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(criterion.name, style: text.titleSmall),
            Text(criterion.description, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final l in RubricLevel.values)
                  ChoiceChip(
                    label: Text(l.label),
                    selected: level == l,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: level == l ? Colors.white : AppColors.textPrimary, fontSize: 12),
                    onSelected: enabled ? (_) => onChanged(l) : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Caso ya resuelto: se muestran la decisión y las notas
class _ResolvedNotes extends StatelessWidget {
  final VerificationCase item;

  const _ResolvedNotes(this.item);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final approved = item.decision == 'Approved';
    return Card(
      color: approved ? AppColors.successContainer : AppColors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(approved ? Icons.check_circle : Icons.cancel, color: approved ? AppColors.success : AppColors.error),
                const SizedBox(width: 8),
                Text(approved ? 'Aprobado' : 'Rechazado', style: text.titleMedium),
                const Spacer(),
                Text(shortDate(item.resolvedAt), style: text.bodySmall),
              ],
            ),
            if (item.rubricNotes != null) ...[
              const SizedBox(height: 12),
              Text(item.rubricNotes!, style: text.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
