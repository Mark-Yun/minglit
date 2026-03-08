import 'package:app_partner/src/ui/shell/partner_shell_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerScaffold extends StatelessWidget {
  const PartnerScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  int _calculateSelectedIndex() {
    return navigationShell.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final coordinator = PartnerShellCoordinator(
      context: context,
      navigationShell: navigationShell,
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(),
        onDestinationSelected: coordinator.onItemTapped,
        indicatorColor: MinglitColors.transparent,
        backgroundColor: colorScheme.surface,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.celebration_outlined),
            selectedIcon: Icon(Icons.celebration),
            label: '파티관리',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money),
            label: '수익관리',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
