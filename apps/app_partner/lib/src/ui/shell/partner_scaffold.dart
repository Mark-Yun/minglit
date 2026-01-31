import 'dart:async';

import 'package:app_partner/src/features/qr/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartnerScaffold extends StatelessWidget {
  const PartnerScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when switching branches, for example in a bottom
      // navigation bar. Support for popping to the initial location of
      // the branch (e.g. to the root of the stack) on tap.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    // Map UI Index to Branch Index
    // UI: [0:Home] [1:Party] [2:QR] [3:Settlement] [4:More]
    // Branches: [0:Home] [1:Party] [2:Settlement] [3:More]

    switch (index) {
      case 0:
        _goBranch(0);
      case 1:
        _goBranch(1);
      case 2:
        // QR Action
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const QRScannerScreen()),
          ),
        );
      case 3:
        _goBranch(2);
      case 4:
        _goBranch(3);
    }
  }

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

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(),
        onDestinationSelected: (index) => _onItemTapped(context, index),
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
