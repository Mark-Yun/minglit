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

    testWidgets(
      'BugReporterWrapper with enabled=false does not render a FAB',
      (tester) async {
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

        // enabled=false suppresses the Stack overlay FAB entirely.
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

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

    // Fix #1858: BugReporterWrapper now renders BugReportFab as a Stack overlay.
    // FAB is hidden by default (bugReportFabVisibleProvider == false).
    testWidgets(
      'BugReporterWrapper FAB hidden by default (provider=false)',
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
        await tester.pump();

        expect(find.text('content'), findsOneWidget);
        // BugReportFab returns SizedBox.shrink() when provider is false
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

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

  // Fix #1466 / Fix #1858: BugReportFab toggle behavior
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

    // Fix #1466 / Fix #1858: BugReportFab는 FAB visible + callback 모두 set 시에만 보임.
    // Fix #1858 이후 BugReporterWrapper가 Stack overlay로 BugReportFab을 직접 렌더링한다.
    // _BugReporterCallbackNotifier와 _BugReportFabVisibleNotifier 모두 private이므로
    // BugReporterWrapper를 마운트하여 실제 callback을 등록하고,
    // notifier.toggle()로 FAB visible 상태를 활성화한다.
    testWidgets('visible when provider is true and callback is set', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              // Fix #1858: FAB is now rendered by BugReporterWrapper Stack overlay,
              // not by Scaffold.floatingActionButton — don't double-mount here.
              body: BugReporterWrapper(child: Text('content')),
            ),
          ),
        ),
      );
      // postFrameCallback fires — BugReporterWrapper registers callback
      await tester.pump();

      // Toggle FAB visible via notifier (StateProvider removed in Riverpod v3)
      container.read(bugReportFabVisibleProvider.notifier).toggle();
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // Fix #1858: Test A — BugReporterWrapper 글로벌 오버레이 FAB 노출 검증
    // provider=true + callback 등록 시 BugReporterWrapper Stack 내에서 FAB 등장
    testWidgets(
      'Test A: BugReporterWrapper shows FAB overlay when provider is true',
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
        // postFrameCallback fires — BugReporterWrapper registers callback
        await tester.pump();

        // FAB hidden by default
        expect(find.byType(FloatingActionButton), findsNothing);

        // Toggle to visible
        container.read(bugReportFabVisibleProvider.notifier).toggle();
        await tester.pump();

        // FAB appears inside the BugReporterWrapper Stack overlay
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    // Fix #1858: Test B — provider=false のとき FAB は見えない (BugReporterWrapper内)
    testWidgets(
      'Test B: BugReporterWrapper hides FAB overlay when provider is false',
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
        await tester.pump();

        // Provider is false by default — no FAB
        expect(find.byType(FloatingActionButton), findsNothing);

        // Toggle on, then toggle off again
        container.read(bugReportFabVisibleProvider.notifier).toggle();
        await tester.pump();
        expect(find.byType(FloatingActionButton), findsOneWidget);

        container.read(bugReportFabVisibleProvider.notifier).toggle();
        await tester.pump();
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    // Fix #1466: BugReportAction은 callback이 등록되어 있을 때만 IconButton을 렌더링.
    // BugReporterWrapper를 마운트하여 실제 callback을 등록한다.
    testWidgets('BugReportAction tap toggles bugReportFabVisibleProvider', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(actions: const [BugReportAction()]),
              body: const BugReporterWrapper(child: Text('content')),
            ),
          ),
        ),
      );
      // postFrameCallback fires — BugReporterWrapper registers callback
      await tester.pump();

      expect(container.read<bool>(bugReportFabVisibleProvider), isFalse);

      await tester.tap(find.byType(IconButton).first);
      await tester.pump();
      expect(container.read<bool>(bugReportFabVisibleProvider), isTrue);

      await tester.tap(find.byType(IconButton).first);
      await tester.pump();
      expect(container.read<bool>(bugReportFabVisibleProvider), isFalse);
    });
  });
}
