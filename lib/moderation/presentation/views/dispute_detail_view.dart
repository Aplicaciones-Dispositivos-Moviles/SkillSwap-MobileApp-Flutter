import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/domain/utils/formatters.dart';
import '../../../shared/presentation/components/justification_dialog.dart';
import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/components/status_chip.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/dispute_detail_bloc.dart';
import '../../domain/models/dispute.dart';
import '../../domain/models/dispute_evidence.dart';

// US35 · Certificado sospechoso: la evidencia del certificado y la decisión del Verificador (verificarlo o rechazarlo).
class DisputeDetailView extends StatelessWidget {
  const DisputeDetailView({super.key});

  Future<void> _decide(BuildContext context, {required bool verify}) async {
    final bloc = context.read<DisputeDetailBloc>();
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => JustificationDialog(
        title: verify ? '¿Verificar este certificado?' : '¿Rechazar este certificado?',
        description: verify
            ? 'El certificado quedará verificado y contará como habilidad demostrada. No se puede deshacer. '
                'Escribe tus observaciones.'
            : 'El certificado quedará rechazado. No se puede deshacer. Escribe tus observaciones.',
        confirmLabel: verify ? 'Verificar' : 'Rechazar',
        maxLength: Dispute.notesMaxLength,
        destructive: !verify,
      ),
    );
    if (notes != null) bloc.add(DisputeResolutionSubmitted(verify: verify, notes: notes));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DisputeDetailBloc, DisputeDetailState>(
      listener: (context, state) async {
        if (state is DisputeDetailLoaded && state.error != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
          // 409: la disputa ya no está pendiente; se vuelve a la lista para que se recargue
          if (state.outdated) Navigator.of(context).pop(true);
        }
        if (state is DisputeResolved) {
          final verified = state.resolved.outcome == Dispute.upheld;
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              icon: Icon(
                verified ? Icons.check_circle : Icons.cancel,
                color: verified ? AppColors.success : AppColors.error,
                size: 40,
              ),
              title: Text(verified ? 'Certificado verificado' : 'Certificado rechazado'),
              content: const Text('Registramos tu decisión y guardamos tus observaciones.'),
              actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Entendido'))],
            ),
          );
          if (context.mounted) Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return switch (state) {
          DisputeDetailLoading() => const Scaffold(body: Center(child: CircularProgressIndicator())),
          DisputeDetailError(:final message) => Scaffold(
              appBar: AppBar(),
              body: MessageView(icon: Icons.error_outline, title: 'No se pudo abrir la disputa', message: message),
            ),
          DisputeDetailLoaded(:final evidence, :final submitting) => _content(context, evidence, submitting),
          DisputeResolved(:final evidence) => _content(context, evidence, true),
        };
      },
    );
  }

  Widget _content(BuildContext context, DisputeEvidence evidence, bool submitting) {
    final text = Theme.of(context).textTheme;
    final dispute = evidence.dispute;
    final certificate = evidence.certificate;
    return Scaffold(
      appBar: AppBar(title: const Text('Certificado sospechoso')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            'La revisión es ciega: no ves de quién es el certificado.',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _ReasonsCard(dispute),
          const SizedBox(height: 12),
          if (certificate == null)
            const _InfoCard(
              title: 'Certificado',
              child: Text('El certificado ya no existe, así que no hay evidencia que revisar.'),
            )
          else
            _CertificateCard(certificate),
          const SizedBox(height: 16),
          if (dispute.isPending)
            ..._decision(context, submitting, enabled: certificate != null)
          else
            _ResolvedCard(dispute),
        ],
      ),
    );
  }

  List<Widget> _decision(BuildContext context, bool submitting, {required bool enabled}) {
    if (submitting) {
      return const [Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))];
    }
    return [
      FilledButton.icon(
        onPressed: enabled ? () => _decide(context, verify: true) : null,
        icon: const Icon(Icons.verified_outlined),
        label: const Text('Verificar certificado'),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: enabled ? () => _decide(context, verify: false) : null,
        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
        icon: const Icon(Icons.block_outlined),
        label: const Text('Rechazar certificado'),
      ),
    ];
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReasonsCard extends StatelessWidget {
  final Dispute dispute;

  const _ReasonsCard(this.dispute);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _InfoCard(
      title: 'Por qué es sospechoso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final reason in dispute.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
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
          Text(
            'Abierta el ${shortDate(dispute.raisedAt)}',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateEvidence certificate;

  const _CertificateCard(this.certificate);

  Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final highRisk = certificate.riskLevel == 'HighRisk';
    final lowRisk = certificate.riskLevel == 'LowRisk';
    final fileUrl = certificate.fileUrl;
    return _InfoCard(
      title: 'Certificado en revisión',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(certificate.courseName, style: text.titleSmall)),
              StatusChip(
                certificate.riskLabel,
                color: highRisk ? AppColors.error : (lowRisk ? AppColors.success : AppColors.warning),
                container:
                    highRisk ? AppColors.errorContainer : (lowRisk ? AppColors.successContainer : AppColors.warningContainer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Field('Institución', certificate.institutionName),
          _Field('Titular leído por el OCR', certificate.holderName),
          if (certificate.holderNameMismatch)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: StatusChip(
                'No coincide con el nombre registrado',
                color: AppColors.error,
                container: AppColors.errorContainer,
                icon: Icons.warning_amber_outlined,
              ),
            ),
          _Field('Fecha de emisión', certificate.issueDateLabel),
          _Field('N.º de certificado', certificate.certificateNumber),
          _Field('Código de verificación', certificate.verificationCode),
          _Field('Registrado el', shortDate(certificate.createdAt)),
          const SizedBox(height: 4),
          if (certificate.verificationUrl.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _open(certificate.verificationUrl),
              icon: const Icon(Icons.link),
              label: const Text('Abrir la verificación oficial'),
            ),
          if (fileUrl != null && fileUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _open(fileUrl),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Ver archivo del certificado'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
          Text(value.isEmpty ? '—' : value, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _ResolvedCard extends StatelessWidget {
  final Dispute dispute;

  const _ResolvedCard(this.dispute);

  @override
  Widget build(BuildContext context) {
    final verified = dispute.outcome == Dispute.upheld;
    return _InfoCard(
      title: 'Tu decisión',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            dispute.outcomeLabel ?? 'Resuelta',
            color: verified ? AppColors.success : AppColors.error,
            container: verified ? AppColors.successContainer : AppColors.errorContainer,
            icon: verified ? Icons.verified_outlined : Icons.block_outlined,
          ),
          const SizedBox(height: 8),
          Text('Resuelta el ${shortDate(dispute.resolvedAt)}'),
          if ((dispute.resolutionNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(dispute.resolutionNotes!),
          ],
        ],
      ),
    );
  }
}
