import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../assessment/application/bloc/cases_bloc.dart';
import '../../../assessment/presentation/views/cases_view.dart';
import '../../../recognition/application/bloc/wallet_bloc.dart';
import '../../../recognition/presentation/views/skillcredits_view.dart';
import '../../../reputation/application/bloc/metrics_bloc.dart';
import '../../../reputation/presentation/views/metrics_view.dart';
import '../../../service_locator.dart';

// Navegación del Verificador (barra inferior de los mock-ups 13, 25 y 29).
// La pestaña Métricas solo aparece para el Verificador senior.
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CasesBloc>(create: (_) => getIt<CasesBloc>()..add(const CasesRequested())),
        BlocProvider<WalletBloc>(create: (_) => getIt<WalletBloc>()..add(const WalletRequested())),
        BlocProvider<MetricsBloc>(create: (_) => getIt<MetricsBloc>()..add(const MetricsRequested())),
      ],
      child: BlocBuilder<CasesBloc, CasesState>(
        builder: (context, cases) {
          final senior = cases is CasesLoaded && cases.isSenior;
          final pending = cases is CasesLoaded ? cases.pending.length : 0;
          final pages = <Widget>[
            const CasesView(),
            const SkillCreditsView(),
            if (senior) const MetricsView(),
          ];
          final index = _index.clamp(0, pages.length - 1);
          return Scaffold(
            body: IndexedStack(index: index, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: [
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: pending > 0,
                    label: Text('$pending'),
                    child: const Icon(Icons.inbox_outlined),
                  ),
                  selectedIcon: const Icon(Icons.inbox),
                  label: 'Casos',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.toll_outlined),
                  selectedIcon: Icon(Icons.toll),
                  label: 'SkillCredits',
                ),
                if (senior)
                  const NavigationDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights),
                    label: 'Métricas',
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
