// Fix #1103: settlement 도메인 테스트 보강

import 'package:app_partner/src/features/settlement/widgets/settlement_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildCard(Map<String, dynamic> item, {VoidCallback? onTap}) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: SettlementCard(item: item, onTap: onTap ?? () {}),
      ),
    );
  }

  group('SettlementCard widget', () {
    testWidgets('renders static label 정산 항목', (tester) async {
      await tester.pumpWidget(
        buildCard({
          'status': 'COMPLETED',
          'net_amount': 93000,
          'created_at': '2026-01-15T10:00:00.000Z',
        }),
      );
      expect(find.text('정산 항목'), findsOneWidget);
    });

    testWidgets('renders net amount with comma formatting', (tester) async {
      await tester.pumpWidget(
        buildCard({
          'status': 'COMPLETED',
          'net_amount': 93000,
          'created_at': '2026-01-15T10:00:00.000Z',
        }),
      );
      expect(find.text('₩93,000'), findsOneWidget);
    });

    testWidgets('renders date as first 10 chars of created_at', (tester) async {
      await tester.pumpWidget(
        buildCard({
          'status': 'COMPLETED',
          'net_amount': 93000,
          'created_at': '2026-01-15T10:00:00.000Z',
        }),
      );
      expect(find.text('2026-01-15'), findsOneWidget);
    });

    testWidgets('renders "-" when created_at is empty', (tester) async {
      await tester.pumpWidget(
        buildCard({
          'status': 'COMPLETED',
          'net_amount': 93000,
          'created_at': '',
        }),
      );
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('renders status badge', (tester) async {
      await tester.pumpWidget(
        buildCard({
          'status': 'COMPLETED',
          'net_amount': 93000,
          'created_at': '2026-01-15T10:00:00.000Z',
        }),
      );
      expect(find.text('지급 완료'), findsOneWidget);
    });

    testWidgets('renders PENDING status badge', (tester) async {
      await tester.pumpWidget(
        buildCard({
          'status': 'PENDING',
          'net_amount': 0,
          'created_at': '2026-02-01T00:00:00.000Z',
        }),
      );
      expect(find.text('정산 대기'), findsOneWidget);
    });

    testWidgets('renders FAILED status badge', (tester) async {
      await tester.pumpWidget(
        buildCard({
          'status': 'FAILED',
          'net_amount': 50000,
          'created_at': '2026-02-10T00:00:00.000Z',
        }),
      );
      expect(find.text('지급 실패'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildCard(
          {
            'status': 'COMPLETED',
            'net_amount': 10000,
            'created_at': '2026-01-15T10:00:00.000Z',
          },
          onTap: () => called = true,
        ),
      );
      await tester.tap(find.byType(InkWell));
      expect(called, isTrue);
    });

    testWidgets('handles missing fields gracefully with defaults', (
      tester,
    ) async {
      await tester.pumpWidget(buildCard({}));
      // Should render without throwing:
      // status defaults to 'PENDING' -> '정산 대기'
      // net_amount defaults to 0 -> '₩0'
      // created_at defaults to '' -> '-'
      expect(find.text('정산 항목'), findsOneWidget);
      expect(find.text('₩0'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('renders negative net_amount with minus prefix', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard({
          'status': 'CANCELED',
          'net_amount': -5000,
          'created_at': '2026-01-15T10:00:00.000Z',
        }),
      );
      expect(find.text('₩-5,000'), findsOneWidget);
    });
  });
}
