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

    testWidgets('shows header regardless of party count', (tester) async {
      final now = DateTime.now();
      final parties = [
        Party(
          id: 'p1',
          partnerId: 'partner1',
          title: '주말 파티',
          createdAt: now,
          updatedAt: now,
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
      expect(find.text('파티별 요약'), findsOneWidget);
    });

    testWidgets('shows celebration icon in header', (tester) async {
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
      expect(find.byIcon(Icons.celebration), findsOneWidget);
    });

    testWidgets('shows multiple party titles when multiple parties given', (
      tester,
    ) async {
      final now = DateTime.now();
      final parties = [
        Party(
          id: 'p1',
          partnerId: 'partner1',
          title: '첫 번째 파티',
          createdAt: now,
          updatedAt: now,
          maxParticipants: 15,
        ),
        Party(
          id: 'p2',
          partnerId: 'partner1',
          title: '두 번째 파티',
          createdAt: now,
          updatedAt: now,
          maxParticipants: 25,
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
      expect(find.text('첫 번째 파티'), findsOneWidget);
      expect(find.text('두 번째 파티'), findsOneWidget);
    });

    testWidgets('shows correct max participants for each party', (
      tester,
    ) async {
      final now = DateTime.now();
      final parties = [
        Party(
          id: 'p1',
          partnerId: 'partner1',
          title: '소규모 파티',
          createdAt: now,
          updatedAt: now,
          maxParticipants: 10,
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
      expect(find.text('최대 10명'), findsOneWidget);
    });
  });
}
