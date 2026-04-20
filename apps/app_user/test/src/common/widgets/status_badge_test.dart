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
      // Fix #1236: MinglitChip(solid) → MinglitBadge(tinted) for hierarchy
      expect(find.byType(MinglitBadge), findsOneWidget);
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

    // Fix #1541: payment_failed / payment_pending 누락 케이스 회귀 방지
    testWidgets('renders 결제중 for payment_pending status', (tester) async {
      await tester.pumpWidget(createTestWidget('payment_pending'));
      expect(find.text('결제중'), findsOneWidget);
    });

    testWidgets('renders 결제실패 for payment_failed status', (tester) async {
      await tester.pumpWidget(createTestWidget('payment_failed'));
      expect(find.text('결제실패'), findsOneWidget);
    });

    testWidgets('payment_failed uses error color', (tester) async {
      await tester.pumpWidget(createTestWidget('payment_failed'));
      final badge = tester.widget<MinglitBadge>(find.byType(MinglitBadge));
      expect(badge.color, MinglitColors.error);
    });

    testWidgets('payment_pending uses info color', (tester) async {
      await tester.pumpWidget(createTestWidget('payment_pending'));
      final badge = tester.widget<MinglitBadge>(find.byType(MinglitBadge));
      expect(badge.color, MinglitColors.info);
    });

    // Fix #1236: 성공 상태(paid/approved)에 success 색상, 오류 상태에 error 색상
    testWidgets('paid and approved use success color (not primary purple)', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget('paid'));
      final badge = tester.widget<MinglitBadge>(find.byType(MinglitBadge));
      expect(badge.color, MinglitColors.success);

      await tester.pumpWidget(createTestWidget('approved'));
      final badge2 = tester.widget<MinglitBadge>(find.byType(MinglitBadge));
      expect(badge2.color, MinglitColors.success);
    });

    testWidgets('pending_review uses warning color', (tester) async {
      await tester.pumpWidget(createTestWidget('pending_review'));
      final badge = tester.widget<MinglitBadge>(find.byType(MinglitBadge));
      expect(badge.color, MinglitColors.warning);
    });

    testWidgets('rejected uses error color', (tester) async {
      await tester.pumpWidget(createTestWidget('rejected'));
      final badge = tester.widget<MinglitBadge>(find.byType(MinglitBadge));
      expect(badge.color, MinglitColors.error);
    });

    testWidgets('cancelled uses neutral color (not error)', (tester) async {
      await tester.pumpWidget(createTestWidget('cancelled'));
      final badge = tester.widget<MinglitBadge>(find.byType(MinglitBadge));
      // Fix #1236: 취소는 오류가 아닌 중립 종료 상태 — error red 사용 금지
      expect(badge.color, isNot(MinglitColors.error));
      expect(badge.color, isNot(MinglitColors.primary));
    });
  });

  group('StatusBadge — dark mode', () {
    Widget createDarkTestWidget(String status) {
      return MaterialApp(
        theme: MinglitTheme.materialThemeDark,
        home: Scaffold(
          body: StatusBadge(status: status),
        ),
      );
    }

    testWidgets('dark mode uses correct brightness', (tester) async {
      await tester.pumpWidget(createDarkTestWidget('paid'));
      final context = tester.element(find.byType(StatusBadge));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('dark mode renders all statuses without error', (tester) async {
      for (final status in [
        'pending',
        'pending_review',
        'approved',
        'paid',
        'rejected',
        'cancelled',
        // Fix #1541: 누락됐던 두 상태도 다크 모드에서 렌더링 검증
        'payment_pending',
        'payment_failed',
      ]) {
        await tester.pumpWidget(createDarkTestWidget(status));
        expect(find.byType(MinglitBadge), findsOneWidget);
      }
    });
  });

  group('MinglitColorSet — semantic color tokens', () {
    test('light set contains all semantic colors from MinglitColors', () {
      expect(MinglitColorSet.light.success, MinglitColors.success);
      expect(MinglitColorSet.light.info, MinglitColors.info);
      expect(MinglitColorSet.light.warning, MinglitColors.warning);
      expect(MinglitColorSet.light.error, MinglitColors.error);
    });

    test('dark set has distinct success/info/warning tokens', () {
      expect(
        MinglitColorSet.dark.success,
        isNot(MinglitColorSet.light.success),
      );
      expect(
        MinglitColorSet.dark.info,
        isNot(MinglitColorSet.light.info),
      );
      expect(
        MinglitColorSet.dark.warning,
        isNot(MinglitColorSet.light.warning),
      );
    });

    test('dark error matches light error (shared)', () {
      expect(MinglitColorSet.dark.error, MinglitColors.error);
    });
  });
}
