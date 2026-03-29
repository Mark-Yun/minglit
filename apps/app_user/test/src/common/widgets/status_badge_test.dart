import 'package:app_user/src/common/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget createTestWidget(String status) {
    return MaterialApp(
      home: Scaffold(
        body: StatusBadge(status: status),
      ),
    );
  }

  group('StatusBadge', () {
    testWidgets('renders 결제대기 for pending status', (tester) async {
      await tester.pumpWidget(createTestWidget('pending'));
      expect(find.text('결제대기'), findsOneWidget);
      expect(find.byType(MinglitChip), findsOneWidget);
    });

    testWidgets('renders 심사중 for pending_review status', (tester) async {
      await tester.pumpWidget(createTestWidget('pending_review'));
      expect(find.text('심사중'), findsOneWidget);
    });

    testWidgets('renders 승인됨 for approved status', (tester) async {
      await tester.pumpWidget(createTestWidget('approved'));
      expect(find.text('승인됨'), findsOneWidget);
    });

    testWidgets('renders 결제완료 for paid status', (tester) async {
      await tester.pumpWidget(createTestWidget('paid'));
      expect(find.text('결제완료'), findsOneWidget);
    });

    testWidgets('renders 반려됨 for rejected status', (tester) async {
      await tester.pumpWidget(createTestWidget('rejected'));
      expect(find.text('반려됨'), findsOneWidget);
    });

    testWidgets('renders 취소됨 for cancelled status', (tester) async {
      await tester.pumpWidget(createTestWidget('cancelled'));
      expect(find.text('취소됨'), findsOneWidget);
    });

    testWidgets('renders 알수없음 for unknown status', (tester) async {
      await tester.pumpWidget(createTestWidget('unknown_status'));
      expect(find.text('알수없음'), findsOneWidget);
    });
  });
}
