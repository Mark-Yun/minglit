import 'package:animations/animations.dart';
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
  static const _rootPaths = {
    '/',
    '/applications',
    '/checkin',
    '/settlement',
    '/more',
  };

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
      body: PageTransitionSwitcher(
        transitionBuilder: (child, animation, secondaryAnimation) =>
            FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
        child: KeyedSubtree(
          key: ValueKey<int>(navigationShell.currentIndex),
          child: navigationShell,
        ),
      ),
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
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: '신청관리',
                ),
                NavigationDestination(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: Icon(Icons.qr_code_scanner),
                  label: '체크인',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_outlined),
                  selectedIcon: Icon(Icons.account_balance),
                  label: '정산',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz_outlined),
                  selectedIcon: Icon(Icons.more_horiz),
                  label: '더보기',
                ),
              ],
            )
          : null,
    );
  }
}
