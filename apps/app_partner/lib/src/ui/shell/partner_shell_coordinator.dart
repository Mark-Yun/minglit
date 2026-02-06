import 'dart:async';

import 'package:app_partner/src/features/qr/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartnerShellCoordinator {
  const PartnerShellCoordinator({
    required this.context,
    required this.navigationShell,
  });

  final BuildContext context;
  final StatefulNavigationShell navigationShell;

  void onItemTapped(int index) {
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

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when switching branches, for example in a bottom
      // navigation bar. Support for popping to the initial location of
      // the branch (e.g. to the root of the stack) on tap.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
