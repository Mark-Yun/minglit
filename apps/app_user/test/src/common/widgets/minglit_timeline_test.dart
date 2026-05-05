// MinglitTimeline regression tests — tone rendering, dot/line structure,
// pulsing (orthogonal flag), trailing/child slots, step connectivity.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: MinglitTheme.materialTheme,
  home: Scaffold(body: child),
);

void main() {
  group('MinglitTimeline', () {
    testWidgets('renders all step titles', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitTimeline(
            children: [
              MinglitTimelineStep(tone: TimelineTone.success, title: 'Step 1'),
              MinglitTimelineStep(tone: TimelineTone.neutral, title: 'Step 2'),
              MinglitTimelineStep(tone: TimelineTone.error, title: 'Step 3'),
            ],
          ),
        ),
      );

      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('Step 3'), findsOneWidget);
    });

    testWidgets('renders trailing Text widget when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitTimeline(
            children: [
              MinglitTimelineStep(
                tone: TimelineTone.success,
                title: 'Done',
                trailing: Text('2026.04.10 19:42'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('2026.04.10 19:42'), findsOneWidget);
    });

    testWidgets('trailing non-Text widget (Icon) renders without assert', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitTimeline(
            children: [
              MinglitTimelineStep(
                tone: TimelineTone.success,
                title: 'With Icon',
                trailing: Icon(Icons.check),
              ),
            ],
          ),
        ),
      );

      expect(find.text('With Icon'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders child widget when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitTimeline(
            children: [
              MinglitTimelineStep(
                tone: TimelineTone.error,
                title: 'Rejected',
                child: Text('심사 사유: 조건 미충족'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('심사 사유: 조건 미충족'), findsOneWidget);
    });

    testWidgets('pulsing=true wraps dot in Transform for any tone', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _wrap(
          MinglitTimeline(
            key: key,
            children: const [
              MinglitTimelineStep(
                tone: TimelineTone.progress,
                pulsing: true,
                title: 'In Progress',
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final transforms = find.descendant(
        of: find.byKey(key),
        matching: find.byType(Transform),
      );
      expect(transforms, findsOneWidget);
    });

    testWidgets('pulsing=false (default) has no Transform on dot', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _wrap(
          MinglitTimeline(
            key: key,
            children: const [
              MinglitTimelineStep(
                tone: TimelineTone.progress,
                title: 'Done',
              ),
            ],
          ),
        ),
      );

      final transforms = find.descendant(
        of: find.byKey(key),
        matching: find.byType(Transform),
      );
      expect(transforms, findsNothing);
    });

    testWidgets('single-step timeline renders without connecting line', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitTimeline(
            children: [
              MinglitTimelineStep(tone: TimelineTone.success, title: 'Only'),
            ],
          ),
        ),
      );

      expect(find.text('Only'), findsOneWidget);
    });

    testWidgets(
      'pulsing transition false→true starts animation, true→false stops',
      (
        tester,
      ) async {
        final pulsingNotifier = ValueNotifier<bool>(false);
        addTearDown(pulsingNotifier.dispose);

        await tester.pumpWidget(
          _wrap(
            ValueListenableBuilder<bool>(
              valueListenable: pulsingNotifier,
              builder: (_, pulsing, __) => MinglitTimeline(
                children: [
                  MinglitTimelineStep(
                    tone: TimelineTone.progress,
                    pulsing: pulsing,
                    title: 'Transition',
                  ),
                ],
              ),
            ),
          ),
        );

        // Scope to MinglitTimeline to avoid matching MaterialApp's route
        // transition Transforms that are present during the initial frame.
        final inTimeline = find.descendant(
          of: find.byType(MinglitTimeline),
          matching: find.byType(Transform),
        );

        expect(inTimeline, findsNothing);

        // false → true: Transform appears and controller animates
        pulsingNotifier.value = true;
        await tester.pump();
        expect(inTimeline, findsOneWidget);
        await tester.pump(const Duration(milliseconds: 300));
        expect(inTimeline, findsOneWidget);

        // true → false: Transform disappears
        pulsingNotifier.value = false;
        await tester.pump();
        expect(inTimeline, findsNothing);
      },
    );

    testWidgets(
      'pulsing=true with disableAnimations=true renders no Transform',
      (tester) async {
        final key = GlobalKey();
        // MediaQuery must be inside MaterialApp; placing it outside has no
        // effect because MaterialApp creates its own MediaQuery from the view.
        await tester.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: MinglitTimeline(
                  key: key,
                  children: const [
                    MinglitTimelineStep(
                      tone: TimelineTone.progress,
                      pulsing: true,
                      title: 'In Progress',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(Transform),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('renders all five tones without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitTimeline(
            children: [
              MinglitTimelineStep(tone: TimelineTone.success, title: 'S'),
              MinglitTimelineStep(tone: TimelineTone.progress, title: 'P'),
              MinglitTimelineStep(tone: TimelineTone.error, title: 'E'),
              MinglitTimelineStep(tone: TimelineTone.neutral, title: 'N'),
              MinglitTimelineStep(tone: TimelineTone.muted, title: 'M'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in ['S', 'P', 'E', 'N', 'M']) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });
}
