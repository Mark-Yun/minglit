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
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
