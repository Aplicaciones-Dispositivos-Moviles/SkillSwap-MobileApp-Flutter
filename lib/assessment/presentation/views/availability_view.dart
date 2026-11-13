import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/utils/formatters.dart';
import '../../../shared/presentation/components/message_view.dart';
import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/cases_bloc.dart';

// T72 · Pantalla de disponibilidad (US23): activar o pausar la recepción de casos nuevos.
// Comparte el CasesBloc del inicio, así que el cambio se refleja allí sin recargar.
class AvailabilityView extends StatelessWidget {
  const AvailabilityView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilidad')),
      body: BlocConsumer<CasesBloc, CasesState>(
        // Solo avisa cuando termina un guardado que falló
        listenWhen: (previous, current) =>
            current is CasesLoaded &&
            current.availabilityError != null &&
            previous is CasesLoaded &&
            previous.updatingAvailability,
        listener: (context, state) {
          if (state is CasesLoaded) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.availabilityError!)));
          }
        },
        builder: (context, state) {
          if (state is! CasesLoaded) {
            return state is CasesError
                ? MessageView(
                    icon: Icons.cloud_off_outlined,
                    title: 'No se pudo cargar tu perfil',
                    message: state.message,
                  )
                : const Center(child: CircularProgressIndicator());
          }
          final profile = state.profile;
          final busy = state.updatingAvailability;
          final subtitle = profile.suspended
              ? 'Suspendido: no se te asignan casos nuevos'
              : profile.available
                  ? 'Estás en el proceso de asignación de casos'
                  : 'En pausa: no se te asignan casos nuevos';
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              if (profile.suspended) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tu cuenta de Verificador está suspendida, por eso no puedes cambiar tu disponibilidad.',
                          style: text.bodyMedium?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text('Recibir casos nuevos', style: text.titleSmall),
                      subtitle: Text(subtitle),
                      value: profile.available,
                      onChanged: profile.suspended || busy
                          ? null
                          : (value) => context.read<CasesBloc>().add(AvailabilityChanged(value)),
                    ),
                    if (busy) const LinearProgressIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Al activarla, entras al proceso de asignación y recibes casos de las habilidades que tienes habilitadas.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Al pausarla, dejas de recibir casos nuevos. Los que ya tienes asignados se mantienen.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Text('Habilidades que revisas', style: text.titleMedium),
              const SizedBox(height: 8),
              if (profile.skillTags.isEmpty)
                Text('Todavía no tienes habilidades habilitadas.', style: text.bodyMedium)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final tag in profile.skillTags) Chip(label: Text(skillLabel(tag)))],
                ),
            ],
          );
        },
      ),
    );
  }
}
