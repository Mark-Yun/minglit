import 'package:flutter/material.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/catalog_tabs.dart';

/// Dev-only design catalog page displaying all design tokens and components.
///
/// Organized into three sections:
/// - **Tokens** (6 tabs): design foundation values
/// - **Widgets** (8 tabs): reusable Minglit components
/// - **Patterns** (1 tab): composited design patterns
///
/// Shared between user and partner apps. Only accessible when
/// `ENVIRONMENT` is `development` or `local`.
class DesignCatalogPage extends StatelessWidget {
  /// Creates a [DesignCatalogPage].
  const DesignCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // Fix #621: 16탭 → 14탭 (토큰 6 + 위젯 8) 재구성; #713: +1 패턴 탭
      length: 15,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Design Catalog'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              // Tokens (6)
              Tab(text: 'Colors'),
              Tab(text: 'Typography'),
              Tab(text: 'Spacing'),
              Tab(text: 'Radius'),
              Tab(text: 'IconSize'),
              Tab(text: 'Animation'),
              // Widgets (8)
              Tab(text: 'Layout'),
              Tab(text: 'Buttons'),
              Tab(text: 'Inputs'),
              Tab(text: 'Cards'),
              Tab(text: 'Feedback'),
              Tab(text: 'Overlay'),
              Tab(text: 'Data'),
              Tab(text: 'Loading'),
              // Patterns (1)
              Tab(text: 'Patterns'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tokens (6)
            ColorsSection(),
            TypographySection(),
            SpacingSection(),
            RadiusSection(),
            IconSizeSection(),
            AnimationSection(),
            // Widgets (8)
            LayoutSection(),
            ButtonsSection(),
            InputsSection(),
            CardsSection(),
            FeedbackSection(),
            OverlaySection(),
            DataSection(),
            LoadingSection(),
            // Patterns (1)
            PatternListSection(),
          ],
        ),
      ),
    );
  }
}
