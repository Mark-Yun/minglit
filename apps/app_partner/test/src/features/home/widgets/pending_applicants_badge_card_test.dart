import 'package:app_partner/src/features/home/widgets/pending_applicants_badge_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingApplicantsBadgeCard', () {
    testWidgets('shows zero state when count is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingApplicantsBadgeCard(count: 0, onTap: () {}),
          ),
        ),
      );
      expect(find.text('대기 중인 신청자가 없습니다'), findsOneWidget);
    });

    testWidgets('shows count when count > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingApplicantsBadgeCard(count: 5, onTap: () {}),
          ),
        ),
      );
      expect(find.text('5명'), findsOneWidget);
      expect(find.text('새 신청자 승인 대기 중'), findsOneWidget);
    });

    testWidgets('shows correct count for single applicant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingApplicantsBadgeCard(count: 1, onTap: () {}),
          ),
        ),
      );
      expect(find.text('1명'), findsOneWidget);
      expect(find.text('새 신청자 승인 대기 중'), findsOneWidget);
    });

    testWidgets('shows correct count for large number of applicants', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingApplicantsBadgeCard(count: 99, onTap: () {}),
          ),
        ),
      );
      expect(find.text('99명'), findsOneWidget);
    });

    testWidgets('shows person_add icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingApplicantsBadgeCard(count: 0, onTap: () {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('shows arrow_forward_ios icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingApplicantsBadgeCard(count: 3, onTap: () {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('does not show zero-state text when count > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingApplicantsBadgeCard(count: 2, onTap: () {}),
          ),
        ),
      );
      expect(find.text('대기 중인 신청자가 없습니다'), findsNothing);
    });
  });
}
