import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/design/app_colors.dart';
import '../../application/bloc/session_bloc.dart';

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

  void _submit() {
    context.read<SessionBloc>().add(SignInRequested(_username.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return BlocConsumer<SessionBloc, SessionState>(
      // Si el login falla (o la sesión venció) se muestra el motivo
      listenWhen: (_, state) => state is Unauthenticated && state.message != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((state as Unauthenticated).message!)));
      },
      builder: (context, state) {
        final loading = state is Authenticating;
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
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
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
                    enabled: !loading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 24),
                  Text('Contraseña', style: text.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _password,
                    enabled: !loading,
                    obscureText: !_showPassword,
                    onSubmitted: (_) => _submit(),
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
                    onPressed: loading ? null : _submit,
                    child: Text(loading ? 'Ingresando…' : 'Iniciar sesión'),
                  ),
                  if (loading)
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
      },
    );
  }
}
