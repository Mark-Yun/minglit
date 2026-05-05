// Fix #2096: regression guard for MinglitTimeline — tone rendering, dot/line
// structure, pulsing (orthogonal flag), trailing/child slots, step connectivity.
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

    testWidgets('renders trailing widget when provided', (tester) async {
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
