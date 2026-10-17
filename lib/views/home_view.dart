import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../theme/colors.dart';

// Inicio del Verificador. Por ahora solo saluda y permite cerrar sesión;
// las opciones según el rol se agregan en la siguiente capa.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillSwap Verificador'),
        actions: [
          TextButton(onPressed: session.signOut, child: const Text('Salir')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${session.user?.username ?? ''}', style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              session.user?.email ?? '',
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
