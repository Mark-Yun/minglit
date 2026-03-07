import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/bug_reporter_wrapper.dart';

void main() {
  group('BugReporterWrapper Widget Tests', () {
    testWidgets('renders child widget correctly', (tester) async {
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        ProviderScope(
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
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: false,
                child: const Text('Test Content'),
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
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: true,
                child: const Center(
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
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: false,
                child: const Text('Stack Child'),
              ),
            ),
          ),
        ),
      );

      // Verify the BugReporterWrapper widget is used (which uses Stack internally)
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
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: true,
                child: const Text('Always Visible'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Always Visible'), findsOneWidget);
    });
  });
}
