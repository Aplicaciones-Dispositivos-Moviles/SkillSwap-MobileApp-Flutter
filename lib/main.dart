import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/session_provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiClient();
  final session = SessionProvider(api, AuthService(api));
  await session.restore(); // recupera la sesión guardada en el teléfono

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<SessionProvider>.value(value: session),
      ],
      child: const SkillSwapVerifierApp(),
    ),
  );
}

class SkillSwapVerifierApp extends StatelessWidget {
  const SkillSwapVerifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return MaterialApp(
      title: 'SkillSwap Verificador',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: session.user == null ? const LoginView() : const HomeView(),
    );
  }
}
