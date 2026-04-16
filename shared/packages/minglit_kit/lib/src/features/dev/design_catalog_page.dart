import 'package:flutter/material.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/catalog_tabs.dart';

/// Dev-only design catalog page displaying all design tokens and components.
///
/// Organized into three sections:
/// - **Tokens** (6 tabs): design foundation values
/// - **Widgets** (9 tabs): reusable Minglit components
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
      // Fix #1475: +1 Settings tab
      length: 16,
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
              // Widgets (9)
              Tab(text: 'Layout'),
              Tab(text: 'Buttons'),
              Tab(text: 'Inputs'),
              Tab(text: 'Cards'),
              Tab(text: 'Feedback'),
              Tab(text: 'Overlay'),
              Tab(text: 'Data'),
              Tab(text: 'Loading'),
              Tab(text: 'Settings'),
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
            // Widgets (9)
            LayoutSection(),
            ButtonsSection(),
            InputsSection(),
            CardsSection(),
            FeedbackSection(),
            OverlaySection(),
            DataSection(),
            LoadingSection(),
            SettingsSection(),
            // Patterns (1)
            PatternListSection(),
          ],
        ),
      ),
    );
  }
}
