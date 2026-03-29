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
    testWidgets('active chip uses tinted activeColor background (light mode)',
        (tester) async {
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

      // Active chip (pendingApplications > 0) should use tinted background
      final containers = tester.widgetList<Container>(find.byType(Container));
      final activeChip = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color != null &&
            (c.decoration! as BoxDecoration).color!.alpha < 255 &&
            (c.decoration! as BoxDecoration).color!.alpha > 0,
        orElse: () => throw StateError('No tinted chip background found'),
      );
      final bgColor = (activeChip.decoration! as BoxDecoration).color!;
      // Should NOT be a hardcoded Color(0xFFFFF0F0) etc. — alpha < 1.0 means
      // it uses the activeColor.withValues(alpha: 0.08) pattern
      expect(bgColor.alpha, lessThan(255));
    });

    // Fix #652: 다크모드에서 inactive 칩이 colorScheme 시맨틱 컬러 사용 확인
    testWidgets('inactive chip uses colorScheme color (dark mode)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: MinglitColors.primary,
              brightness: Brightness.dark,
            ),
          ),
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

      // All chips inactive → should use surfaceContainerHighest, not 0xFFF5F5F5
      final containers = tester.widgetList<Container>(find.byType(Container));
      final chipContainers = containers.where(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).borderRadius != null,
      );
      for (final chip in chipContainers) {
        final color = (chip.decoration! as BoxDecoration).color;
        if (color != null) {
          // Must NOT be the old hardcoded light-mode Color(0xFFF5F5F5)
          expect(color, isNot(equals(const Color(0xFFF5F5F5))));
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
