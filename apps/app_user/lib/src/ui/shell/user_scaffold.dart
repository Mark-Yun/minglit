import 'dart:ui';

import 'package:app_user/src/ui/shell/nav_visibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Shell scaffold with bottom navigation for the User app.
///
/// 2 tabs: 홈 / 마이
class UserScaffold extends ConsumerWidget {
  const UserScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentIndex = navigationShell.currentIndex;
    final isVisible = currentIndex != 0 || ref.watch(navVisibilityProvider);

    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: isVisible ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: ColoredBox(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    child: SafeArea(
                      top: false,
                      child: NavigationBar(
                        elevation: 0,
                        surfaceTintColor: MinglitColors.transparent,
                        shadowColor: MinglitColors.transparent,
                        selectedIndex: currentIndex,
                        onDestinationSelected: _goBranch,
                        indicatorColor: colorScheme.surface.withValues(
                          alpha: 0.5,
                        ),
                        backgroundColor: MinglitColors.transparent,
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: '홈',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.person_outline),
                            selectedIcon: Icon(Icons.person),
                            label: '마이',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
