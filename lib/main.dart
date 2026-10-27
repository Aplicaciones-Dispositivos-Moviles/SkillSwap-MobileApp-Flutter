import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'iam/application/bloc/session_bloc.dart';
import 'iam/presentation/views/login_view.dart';
import 'service_locator.dart';
import 'shared/infrastructure/network/session_token.dart';
import 'shared/presentation/design/app_theme.dart';
import 'shared/presentation/views/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();

  final session = getIt<SessionBloc>();
  // Si el backend rechaza el token (401), la app vuelve al login
  getIt<SessionToken>().onExpired = () => session.add(const SessionExpired());

  runApp(
    BlocProvider<SessionBloc>.value(
      value: session..add(const SessionRestoreRequested()), // recupera la sesión guardada en el teléfono
      child: const SkillSwapVerifierApp(),
    ),
  );
}

class SkillSwapVerifierApp extends StatelessWidget {
  const SkillSwapVerifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap Verificador',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: BlocBuilder<SessionBloc, SessionState>(
        // Solo cambia de pantalla al entrar o salir; el login maneja sus propios estados
        buildWhen: (previous, current) => (previous is Authenticated) != (current is Authenticated) ||
            previous is SessionUnknown,
        builder: (context, state) => switch (state) {
          SessionUnknown() => const Scaffold(body: Center(child: CircularProgressIndicator())),
          Authenticated(:final user) => MainLayout(key: ValueKey(user.id)),
          _ => const LoginView(),
        },
      ),
    );
  }
}
