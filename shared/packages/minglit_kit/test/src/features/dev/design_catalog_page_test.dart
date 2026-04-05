import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/dev/design_catalog_page.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: const DesignCatalogPage(),
    );
  }

  /// Switch to a tab by index using DefaultTabController.
  Future<void> switchToTab(WidgetTester tester, int index) async {
    final scaffold = tester.element(find.byType(Scaffold).first);
    final controller = DefaultTabController.of(scaffold);
    controller.index = index;
    // Multiple pumps to ensure the TabBarView has time to rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Tab indices: Tokens(0-5), Widgets(6-13), Patterns(14)
  // 0:Colors, 1:Typography, 2:Spacing, 3:Radius, 4:IconSize, 5:Animation
  // 6:Layout, 7:Buttons, 8:Inputs, 9:Cards, 10:Feedback, 11:Overlay,
  // 12:Data, 13:Loading, 14:Patterns

  group('DesignCatalogPage tab structure', () {
    testWidgets('has 15 tabs total', (tester) async {
      await tester.pumpWidget(buildApp());

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 15);
    });

    testWidgets('tab labels match spec order', (tester) async {
      await tester.pumpWidget(buildApp());

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      final labels = tabBar.tabs.map((tab) => (tab as Tab).text).toList();

      expect(labels, [
        // Tokens (6)
        'Colors', 'Typography', 'Spacing', 'Radius', 'IconSize', 'Animation',
        // Widgets (8)
        'Layout', 'Buttons', 'Inputs', 'Cards',
        'Feedback', 'Overlay', 'Data', 'Loading',
        // Patterns (1)
        'Patterns',
      ]);
    });

    testWidgets('Colors tab renders on initial load', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Light Colors'), findsOneWidget);
      expect(find.text('Dark Colors'), findsOneWidget);
    });
  });

  group('Widget sections render Minglit components', () {
    testWidgets('Layout tab (6) shows MinglitSection', (tester) async {
      await tester.pumpWidget(buildApp());
      await switchToTab(tester, 6);
      expect(find.text('MinglitSection'), findsOneWidget);
    });

    testWidgets('Buttons tab (7) shows ElevatedButton', (tester) async {
      await tester.pumpWidget(buildApp());
      await switchToTab(tester, 7);
      expect(find.text('ElevatedButton'), findsOneWidget);
    });

    testWidgets('Feedback tab (10) shows MinglitEmptyState', (tester) async {
      await tester.pumpWidget(buildApp());
      await switchToTab(tester, 10);
      expect(find.text('MinglitEmptyState'), findsOneWidget);
    });

    testWidgets('Loading tab (13) shows MinglitSkeleton', (tester) async {
      await tester.pumpWidget(buildApp());
      await switchToTab(tester, 13);
      expect(find.text('MinglitSkeleton'), findsOneWidget);
    });

    testWidgets('Cards tab (9) shows Card Elevations', (tester) async {
      await tester.pumpWidget(buildApp());
      await switchToTab(tester, 9);
      expect(find.text('Card Elevations'), findsOneWidget);
    });

    testWidgets('Data tab (12) shows MinglitParticipantGauge', (tester) async {
      await tester.pumpWidget(buildApp());
      await switchToTab(tester, 12);
      expect(find.text('MinglitParticipantGauge'), findsOneWidget);
    });

    testWidgets('Overlay tab (11) shows AlertDialog', (tester) async {
      await tester.pumpWidget(buildApp());
      await switchToTab(tester, 11);
      expect(find.text('AlertDialog'), findsOneWidget);
    });

    testWidgets('Inputs tab (8) shows TextField', (tester) async {
      await tester.pumpWidget(buildApp());
      await switchToTab(tester, 8);
      expect(find.text('TextField'), findsOneWidget);
    });
  });
}
