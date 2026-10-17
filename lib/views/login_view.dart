import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../theme/colors.dart';

// Inicio de sesión del Verificador (mismo diseño que el login del Estudiante)
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(SessionProvider session) async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese usuario y contraseña')),
      );
      return;
    }
    final ok = await session.signIn(_username.text.trim(), _password.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(session.errorMessage)));
    }
    // Si salió bien, main.dart cambia solo a la pantalla de inicio
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('⇄', style: text.headlineSmall?.copyWith(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              Text('SkillSwap Verificador', textAlign: TextAlign.center, style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Revisa casos y cuida la calidad de la plataforma',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Text('Inicia sesión', style: text.headlineSmall),
              const SizedBox(height: 24),
              Text('Usuario', style: text.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _username,
                enabled: !session.loading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 24),
              Text('Contraseña', style: text.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _password,
                enabled: !session.loading,
                obscureText: !_showPassword,
                onSubmitted: (_) => _submit(session),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    child: Text(_showPassword ? 'Ocultar' : 'Ver'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: session.loading ? null : () => _submit(session),
                child: Text(session.loading ? 'Ingresando…' : 'Iniciar sesión'),
              ),
              if (session.loading)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Puede tardar si el servidor estaba dormido',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
