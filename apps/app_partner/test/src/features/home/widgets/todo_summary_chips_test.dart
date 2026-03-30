import 'package:app_partner/src/features/home/widgets/todo_summary_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  group('TodoSummaryChips', () {
    testWidgets('renders three chips: 승인 대기, 다가오는 이벤트, 미답변 리뷰', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoSummaryChips(
              pendingApplications: 0,
              upcomingEvents: 0,
              onPendingTap: () {},
              onUpcomingTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('승인 대기'), findsOneWidget);
      expect(find.text('다가오는 이벤트'), findsOneWidget);
      // Third chip is '미답변 리뷰' but comingSoon renders '준비 중'
      expect(find.text('준비 중'), findsOneWidget);
    });

    testWidgets('count > 0 chip shows count badge with active color', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoSummaryChips(
              pendingApplications: 3,
              upcomingEvents: 0,
              onPendingTap: () {},
              onUpcomingTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('count == 0 chip does not show count badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoSummaryChips(
              pendingApplications: 0,
              upcomingEvents: 0,
              onPendingTap: () {},
              onUpcomingTap: () {},
            ),
          ),
        ),
      );
      // Both non-comingSoon chips show '0' text with inactive color
      expect(find.text('0'), findsNWidgets(2));
      // comingSoon chip shows '-' instead of count
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('tapping 승인 대기 chip invokes onPendingTap callback', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoSummaryChips(
              pendingApplications: 2,
              upcomingEvents: 0,
              onPendingTap: () => called = true,
              onUpcomingTap: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('승인 대기'));
      expect(called, isTrue);
    });

    // Fix #652: 하드코딩 색상 → 시맨틱 컬러 교체 회귀 방지
    testWidgets('active chip uses tinted activeColor background (light mode)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: MinglitColors.primary),
          ),
          home: Scaffold(
            body: TodoSummaryChips(
              pendingApplications: 3,
              upcomingEvents: 0,
              onPendingTap: () {},
              onUpcomingTap: () {},
            ),
          ),
        ),
      );

      // 승인 대기 chip (active) should use error color tint
      final expected = MinglitColors.error.withValues(alpha: 0.08);
      final chipContainers = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).borderRadius != null,
        ),
      );
      expect(
        chipContainers.any(
          (c) => (c.decoration! as BoxDecoration).color == expected,
        ),
        isTrue,
        reason: 'Active chip should use activeColor.withValues(alpha: 0.08)',
      );
    });

    // Fix #652: 다크모드에서 inactive 칩이 colorScheme 시맨틱 컬러 사용 확인
    testWidgets('inactive chip uses colorScheme color (dark mode)', (
      tester,
    ) async {
      final darkTheme = ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: MinglitColors.primary,
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: TodoSummaryChips(
              pendingApplications: 0,
              upcomingEvents: 0,
              onPendingTap: () {},
              onUpcomingTap: () {},
            ),
          ),
        ),
      );

      // All chips inactive → should use surfaceContainerHighest
      final context = tester.element(find.byType(TodoSummaryChips));
      final expected = Theme.of(context).colorScheme.surfaceContainerHighest;
      final chipContainers = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).borderRadius != null,
        ),
      );
      for (final chip in chipContainers) {
        final color = (chip.decoration! as BoxDecoration).color;
        if (color != null) {
          expect(color, equals(expected));
        }
      }
    });

    testWidgets('tapping 미답변 리뷰 chip shows a SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoSummaryChips(
              pendingApplications: 0,
              upcomingEvents: 0,
              onPendingTap: () {},
              onUpcomingTap: () {},
            ),
          ),
        ),
      );
      // comingSoon chip renders '준비 중' as its display text
      await tester.tap(find.text('준비 중'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
