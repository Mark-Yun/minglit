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
                enabled: false,
                child: testChild,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Child Widget'), findsOneWidget);
    });

    testWidgets('BugReporterWrapper does not render a FAB directly', (
      tester,
    ) async {
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

      // BugReporterWrapper itself does not render a FAB.
      // FAB is in Scaffold.floatingActionButton (home_page), not here.
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

    // BugReporterWrapper registers _showReportDialog via bugReporterCallbackProvider.
    // FAB (#1466) is in Scaffold.floatingActionButton, not inside BugReporterWrapper.
    testWidgets('BugReporterWrapper does not render a FAB directly', (
      tester,
    ) async {
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

      expect(find.text('content'), findsOneWidget);
      // FAB lives in Scaffold.floatingActionButton (home_page), not here
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    // Regression test for #1285: callback is registered in provider after mount.
    testWidgets(
      'bugReporterCallbackProvider is set when BugReporterWrapper is mounted',
      (
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
      },
    );

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

  // Fix #1466: BugReportFab toggle behavior
  group('BugReportFab', () {
    testWidgets('hidden by default (bugReportFabVisibleProvider == false)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              floatingActionButton: BugReportFab(),
              body: Text('content'),
            ),
          ),
        ),
      );

      // Default: FAB not visible
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('visible when provider is true and callback is set', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          bugReportFabVisibleProvider.overrideWith((_) => true),
          bugReporterCallbackProvider.overrideWith(
            () => _TestCallbackNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              floatingActionButton: BugReportFab(),
              body: Text('content'),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('BugReportAction tap toggles bugReportFabVisibleProvider', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          bugReporterCallbackProvider.overrideWith(
            () => _TestCallbackNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(actions: const [BugReportAction()]),
              body: const Text('content'),
            ),
          ),
        ),
      );

      expect(container.read(bugReportFabVisibleProvider), isFalse);

      await tester.tap(find.byType(IconButton).first);
      expect(container.read(bugReportFabVisibleProvider), isTrue);

      await tester.tap(find.byType(IconButton).first);
      expect(container.read(bugReportFabVisibleProvider), isFalse);
    });
  });
}

class _TestCallbackNotifier extends Notifier<Future<void> Function()?> {
  @override
  Future<void> Function()? build() => () async {};
}
