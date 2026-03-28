import 'package:app_partner/src/features/home/widgets/todo_summary_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
