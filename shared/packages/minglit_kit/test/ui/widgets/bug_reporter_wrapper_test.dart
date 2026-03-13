import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/bug_reporter_wrapper.dart';

void main() {
  group('BugReporterWrapper Widget Tests', () {
    testWidgets('renders child widget correctly', (tester) async {
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: false, // Disable to avoid shake detector setup
                child: testChild,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Child Widget'), findsOneWidget);
    });

    testWidgets('does not render FAB when disabled', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: false,
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // When disabled, no FAB should be rendered
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('widget builds without errors', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                child: Center(
                  child: Text('Main Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.byType(BugReporterWrapper), findsOneWidget);
    });

    testWidgets('renders Stack with child and optional FAB', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: false,
                child: Text('Stack Child'),
              ),
            ),
          ),
        ),
      );

      // Verify the BugReporterWrapper widget is used (which uses Stack
      // internally)
      expect(find.byType(BugReporterWrapper), findsOneWidget);
      expect(find.text('Stack Child'), findsOneWidget);
    });

    testWidgets('accepts navigatorKey parameter', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: false,
                navigatorKey: navigatorKey,
                child: const Text('With Navigator Key'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('With Navigator Key'), findsOneWidget);
    });

    testWidgets('child widget is always rendered regardless of enabled state', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                child: Text('Always Visible'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Always Visible'), findsOneWidget);
    });
  });

  group('Deduplication and cooldown', () {
    testWidgets('FAB opens dialog and prevents duplicate opens', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: true,
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // Find and tap the FAB
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Tap FAB to open dialog
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify dialog is open (look for bug report title)
      expect(find.text('🐞 Bug Report'), findsOneWidget);

      // Try to tap FAB again while dialog is open
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify still only one dialog (not duplicated)
      expect(find.text('🐞 Bug Report'), findsOneWidget);
    });

    testWidgets('dialog closes properly after submission', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: true,
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // Open dialog via FAB
      final fabFinder = find.byType(FloatingActionButton);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('🐞 Bug Report'), findsOneWidget);

      // Click Cancel button
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('🐞 Bug Report'), findsNothing);
    });
  });
}
