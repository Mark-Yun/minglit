import 'package:app_partner/src/features/home/widgets/todo_summary_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoSummaryChips', () {
    testWidgets('renders three chips: 승인 대기, 다가오는 이벤트, 준비 중',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoSummaryChips(
              pendingCount: 0,
              upcomingCount: 0,
              preparingCount: 0,
              onPendingTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('승인 대기'), findsOneWidget);
      expect(find.text('다가오는 이벤트'), findsOneWidget);
      expect(find.text('준비 중'), findsOneWidget);
    });

    testWidgets('count > 0 chip shows count badge with active color',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoSummaryChips(
              pendingCount: 3,
              upcomingCount: 0,
              preparingCount: 0,
              onPendingTap: () {},
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
              pendingCount: 0,
              upcomingCount: 0,
              preparingCount: 0,
              onPendingTap: () {},
            ),
          ),
        ),
      );
      // No numeric badge text should appear when all counts are zero
      expect(find.text('0'), findsNothing);
    });

    testWidgets('tapping 승인 대기 chip invokes onPendingTap callback',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoSummaryChips(
              pendingCount: 2,
              upcomingCount: 0,
              preparingCount: 0,
              onPendingTap: () => called = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('승인 대기'));
      expect(called, isTrue);
    });

    testWidgets('tapping 준비 중 chip shows a SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoSummaryChips(
              pendingCount: 0,
              upcomingCount: 0,
              preparingCount: 1,
              onPendingTap: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('준비 중'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
