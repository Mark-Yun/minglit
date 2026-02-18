import 'package:app_partner/src/ui/shell/partner_shell_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartnerScaffold extends StatelessWidget {
  const PartnerScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  int _calculateSelectedIndex() {
    final branchIndex = navigationShell.currentIndex;
    // Map Branch Index to UI Index
    switch (branchIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Party
      case 2:
        return 3; // Settlement
      case 3:
        return 4; // More
      default:
        return 0;
    }
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
        indicatorColor: Colors.transparent,
        backgroundColor: colorScheme.surface,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          const NavigationDestination(
            icon: Icon(Icons.celebration_outlined),
            selectedIcon: Icon(Icons.celebration),
            label: '파티',
          ),
          NavigationDestination(
            // Custom QR Button look
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.qr_code_scanner,
                color: colorScheme.onPrimary,
                size: 28,
              ),
            ),
            label: '',
            tooltip: 'QR 스캔',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: '정산',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu),
            label: '더보기',
          ),
        ],
      ),
    );
  }
}
