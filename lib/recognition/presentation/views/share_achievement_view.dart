import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../iam/application/bloc/session_bloc.dart';
import '../../../shared/domain/utils/formatters.dart';
import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/share_bloc.dart';

// T58 · Mock-ups 26 "Compartir logro", 26b (menú de compartir de Android) y 26e1 (sin credencial).
class ShareAchievementView extends StatelessWidget {
  const ShareAchievementView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShareBloc, ShareState>(
      listenWhen: (_, state) => state is ShareReady && state.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((state as ShareReady).error!)));
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            title: const Text('Compartir logro'),
          ),
          body: switch (state) {
            ShareLoading() => const Center(child: CircularProgressIndicator()),
            ShareNoCredential() => MessageView(
                icon: Icons.workspace_premium_outlined,
                title: 'Aún no tienes una credencial',
                message: 'Completa la ruta de una habilidad y habilítate como Verificador para poder compartir tu logro.',
                actionLabel: 'Volver',
                onAction: () => Navigator.pop(context),
              ),
            ShareError(:final message) => MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudo preparar tu credencial',
                message: message,
                actionLabel: 'Reintentar',
                onAction: () => context.read<ShareBloc>().add(const ShareRequested()),
              ),
            final ShareReady ready => _ShareContent(ready),
          },
        );
      },
    );
  }
}

class _ShareContent extends StatelessWidget {
  final ShareReady state;

  const _ShareContent(this.state);

  Future<void> _copy(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
    }
  }

  Future<void> _share(String publication, String skillName) async {
    // Abre el menú de compartir de Android (LinkedIn, correo, copiar…)
    await SharePlus.instance.share(ShareParams(text: publication, subject: 'Mi credencial verificada: $skillName'));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final session = context.watch<SessionBloc>().state;
    final username = session is Authenticated ? session.user.username : '';
    final credential = state.credential;
    final title = state.rank == null ? 'Verificador' : 'Verificador · Rango ${state.rank}';
    final skillName = credential?.skillName ?? skillLabel(state.selectedTag);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Comparte tu credencial verificable', style: text.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Incluye un enlace público para que cualquiera compruebe tu experiencia.',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Text('VISTA PREVIA DE LA PUBLICACIÓN', style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        username.isEmpty ? '?' : username.substring(0, username.length < 2 ? 1 : 2).toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(username, style: text.titleSmall)),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.generating)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  )
                else if (credential != null)
                  Text(credential.shareText, style: text.bodyMedium),
                const SizedBox(height: 12),
                // Tarjeta de la credencial
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neutralSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.verified, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CREDENCIAL VERIFICADA',
                                    style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
                                Text(title, style: text.titleSmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(skillName, style: text.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${state.reviewCount} casos · ${state.rating.toStringAsFixed(1)} / 5 · ${state.balance} SkillCredits',
                        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      if (credential != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          credential.url.replaceFirst(RegExp(r'^https?://'), ''),
                          style: text.bodySmall?.copyWith(color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Habilidades a destacar', style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in state.skillTags)
              ChoiceChip(
                label: Text(skillLabel(tag)),
                selected: tag == state.selectedTag,
                onSelected: state.generating ? null : (_) => context.read<ShareBloc>().add(ShareSkillSelected(tag)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: credential == null ? null : () => _copy(context, credential.url),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar enlace público'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: credential == null ? null : () => _share(credential.publication, credential.skillName),
          icon: const Icon(Icons.share),
          label: const Text('Compartir en LinkedIn'),
        ),
      ],
    );
  }
}
