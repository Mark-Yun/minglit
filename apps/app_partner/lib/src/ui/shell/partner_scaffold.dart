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

  /// Root paths where bottom nav should be visible.
  /// Sub-routes (deeper paths) hide the bottom nav.
  static const _rootPaths = {'/', '/parties', '/settlement', '/more'};

  int _calculateSelectedIndex() {
    return navigationShell.currentIndex;
  }

  // Fix #143: Hide bottom nav on sub-screens so users don't get
  // confused by navigation when a back button is present.
  bool _shouldShowBottomNav(BuildContext context) {
    final uri = GoRouterState.of(context).uri.path;
    return _rootPaths.contains(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final coordinator = PartnerShellCoordinator(
      context: context,
      navigationShell: navigationShell,
    );
    final showBottomNav = _shouldShowBottomNav(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: showBottomNav
          ? NavigationBar(
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
            )
          : null,
    );
  }
}
