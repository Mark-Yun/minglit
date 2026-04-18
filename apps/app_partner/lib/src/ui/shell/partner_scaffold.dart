import 'package:animations/animations.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/ui/shell/partner_shell_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #1533: tab → branch 인덱스 매핑을 위한 내부 레코드.
typedef _TabEntry = ({int branchIndex, NavigationDestination destination});

class PartnerScaffold extends ConsumerWidget {
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

  // Fix #143: Hide bottom nav on sub-screens so users don't get
  // confused by navigation when a back button is present.
  bool _shouldShowBottomNav(BuildContext context) {
    final uri = GoRouterState.of(context).uri.path;
    return _rootPaths.contains(uri);
  }

  /// Fix #1533: 권한에 따라 표시할 탭 목록 반환.
  /// settlement 탭은 SETTLEMENT_VIEW 권한을 가진 사용자만 볼 수 있다.
  static List<_TabEntry> _buildTabs({required bool hasSettlementAccess}) => [
    (
      branchIndex: 0,
      destination: const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: '홈',
      ),
    ),
    (
      branchIndex: 1,
      destination: const NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: '신청관리',
      ),
    ),
    (
      branchIndex: 2,
      destination: const NavigationDestination(
        icon: Icon(Icons.qr_code_scanner_outlined),
        selectedIcon: Icon(Icons.qr_code_scanner),
        label: '체크인',
      ),
    ),
    if (hasSettlementAccess)
      (
        branchIndex: 3,
        destination: const NavigationDestination(
          icon: Icon(Icons.account_balance_outlined),
          selectedIcon: Icon(Icons.account_balance),
          label: '정산',
        ),
      ),
    (
      branchIndex: 4,
      destination: const NavigationDestination(
        icon: Icon(Icons.more_horiz_outlined),
        selectedIcon: Icon(Icons.more_horiz),
        label: '더보기',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final coordinator = PartnerShellCoordinator(
      context: context,
      navigationShell: navigationShell,
    );
    final showBottomNav = _shouldShowBottomNav(context);

    // Fix #1533: 권한 로드 중에는 fail-closed(settlement 숨김).
    final settlementAccessAsync = ref.watch(hasSettlementAccessProvider);
    final hasSettlementAccess = settlementAccessAsync.maybeWhen(
      data: (access) => access,
      orElse: () => false,
    );

    final tabs = _buildTabs(hasSettlementAccess: hasSettlementAccess);

    // Fix #1533: 현재 branch 인덱스를 표시 인덱스로 매핑.
    final currentBranch = navigationShell.currentIndex;
    final selectedDisplayIndex = tabs.indexWhere(
      (tab) => tab.branchIndex == currentBranch,
    );

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
              // Fix #1533: settlement 탭이 숨겨져 selectedDisplayIndex == -1이면
              // 홈(0)으로 폴백.
              selectedIndex: selectedDisplayIndex < 0 ? 0 : selectedDisplayIndex,
              onDestinationSelected: (displayIndex) =>
                  coordinator.onItemTapped(tabs[displayIndex].branchIndex),
              indicatorColor: MinglitColors.transparent,
              backgroundColor: colorScheme.surface,
              destinations: tabs.map((tab) => tab.destination).toList(),
            )
          : null,
    );
  }
}
