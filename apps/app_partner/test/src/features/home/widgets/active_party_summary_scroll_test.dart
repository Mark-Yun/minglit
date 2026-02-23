import 'package:app_partner/src/features/home/widgets/active_party_summary_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  group('ActivePartySummaryScroll', () {
    testWidgets('shows empty state when no parties', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivePartySummaryScroll(
              parties: const [],
              onPartyTap: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('운영 중인 파티가 없습니다'), findsOneWidget);
      expect(find.text('파티별 요약'), findsOneWidget);
    });

    testWidgets('shows party cards when parties exist', (tester) async {
      final now = DateTime.now();
      final parties = [
        Party(
          id: 'p1',
          partnerId: 'partner1',
          title: '금요 직장인 파티',
          createdAt: now,
          updatedAt: now,
          maxParticipants: 30,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivePartySummaryScroll(
              parties: parties,
              onPartyTap: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('금요 직장인 파티'), findsOneWidget);
      expect(find.text('최대 30명'), findsOneWidget);
    });
  });
}
