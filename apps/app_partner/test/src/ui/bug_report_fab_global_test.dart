// Regression tests for #1858: BugReportFab must be visible in partner app
// via BugReporterWrapper overlay (Fix #1858, PR #1885).
//
// Failure condition: someone removes BugReporterWrapper from main.dart or
// sets enabled: false — both scenarios are covered below.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  group('BugReportFab 회귀 (#1858)', () {
    // Verifies the core mechanism: BugReporterWrapper registers the callback
    // that allows BugReportFab to render. Without it the FAB stays invisible
    // even when bugReportFabVisibleProvider is true.
    testWidgets(
      'BugReporterWrapper 없으면 FAB toggle해도 나타나지 않는다',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              // No BugReporterWrapper — simulates the bug from #1858.
              home: Scaffold(body: Text('content')),
            ),
          ),
        );
        await tester.pump();

        // Toggle visible — but callback was never registered, so FAB stays hidden.
        container.read(bugReportFabVisibleProvider.notifier).toggle();
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'BugReporterWrapper 있으면 FAB toggle 시 나타난다',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: BugReporterWrapper(child: Text('content')),
              ),
            ),
          ),
        );
        // postFrameCallback fires — BugReporterWrapper registers callback.
        await tester.pump();

        container.read(bugReportFabVisibleProvider.notifier).toggle();
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'enabled=false 시 FAB toggle해도 나타나지 않는다',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: BugReporterWrapper(
                  enabled: false,
                  child: Text('content'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        container.read(bugReportFabVisibleProvider.notifier).toggle();
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );
  });
}
