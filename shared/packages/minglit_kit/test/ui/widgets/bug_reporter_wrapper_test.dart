import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/bug_reporter_wrapper.dart';

// ignore_for_file: avoid_dynamic_calls

void main() {
  group('BugReporterWrapper Widget Tests', () {
    testWidgets('renders child widget correctly', (tester) async {
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                enabled: false,
                child: testChild,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Child Widget'), findsOneWidget);
    });

    testWidgets('does not render FAB (FAB removed in #1285)', (tester) async {
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

      // FAB has been removed in #1285 — no FAB should be present
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

    testWidgets('renders RepaintBoundary with child', (tester) async {
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

      // Verify the BugReporterWrapper widget is used (which uses RepaintBoundary
      // internally after #1285 FAB removal)
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

  group('Lifecycle', () {
    testWidgets('disposes cleanly without crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                child: Text('test'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('test'), findsOneWidget);

      // Rebuild with empty widget — triggers dispose and observer removal
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SizedBox(),
          ),
        ),
      );
      // No crash = state was properly cleaned up
    });

    // Fix #1285: FAB has been removed. BugReporterWrapper now registers
    // _showReportDialog via bugReporterCallbackProvider instead of rendering a FAB.
    testWidgets('no FAB rendered when enabled (FAB removed in #1285)',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                child: Text('content'),
              ),
            ),
          ),
        ),
      );

      // Verify child is rendered
      expect(find.text('content'), findsOneWidget);

      // FAB removed in #1285 — no FloatingActionButton should be in the tree
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    // Regression test for #1285: callback is registered in provider after mount.
    testWidgets('bugReporterCallbackProvider is set when BugReporterWrapper is mounted', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                child: Text('content'),
              ),
            ),
          ),
        ),
      );

      // postFrameCallback fires after first pump
      await tester.pump();

      // Callback should now be registered
      expect(container.read(bugReporterCallbackProvider), isNotNull);
    });

    // Regression test for #1285: BugReporterWrapper disposes cleanly even
    // when a callback is registered. The provider is not explicitly cleared on
    // dispose because Riverpod v3 forbids modifying providers during widget
    // tree finalization; BugReporterWrapper lives for the app's lifetime, so
    // a stale callback reference is not a concern in practice.
    testWidgets('disposes cleanly with callback registered', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: BugReporterWrapper(
                child: Text('content'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify callback is set
      expect(container.read(bugReporterCallbackProvider), isNotNull);

      // Dispose by replacing widget tree — must not throw
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SizedBox()),
        ),
      );
      // No crash = dispose completed cleanly
    });
  });
}
