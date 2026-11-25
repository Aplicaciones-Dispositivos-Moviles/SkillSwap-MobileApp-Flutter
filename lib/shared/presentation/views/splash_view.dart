import 'package:flutter/material.dart';

import '../design/app_colors.dart';

// Pantalla de carga mientras se recupera la sesión guardada: el símbolo de SkillSwap y "Verificador".
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/skillswap_symbol.png', width: 160, height: 160),
            Text('Verificador', style: text.titleLarge?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 24),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}
