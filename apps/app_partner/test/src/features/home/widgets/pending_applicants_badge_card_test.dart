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
  });
}
