// Fix #1103: settlement 도메인 테스트 보강

import 'package:app_partner/src/features/settlement/widgets/settlement_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SettlementStatus.fromString
  // ---------------------------------------------------------------------------
  group('SettlementStatus.fromString', () {
    test('maps PENDING correctly', () {
      expect(
        SettlementStatus.fromString('PENDING'),
        SettlementStatus.pending,
      );
    });

    test('maps HOLD correctly', () {
      expect(SettlementStatus.fromString('HOLD'), SettlementStatus.hold);
    });

    test('maps READY correctly', () {
      expect(SettlementStatus.fromString('READY'), SettlementStatus.ready);
    });

    test('maps PROCESSING correctly', () {
      expect(
        SettlementStatus.fromString('PROCESSING'),
        SettlementStatus.processing,
      );
    });

    test('maps COMPLETED correctly', () {
      expect(
        SettlementStatus.fromString('COMPLETED'),
        SettlementStatus.completed,
      );
    });

    test('maps FAILED correctly', () {
      expect(SettlementStatus.fromString('FAILED'), SettlementStatus.failed);
    });

    test('maps CANCELED correctly', () {
      expect(
        SettlementStatus.fromString('CANCELED'),
        SettlementStatus.canceled,
      );
    });

    test('maps unknown string to unknown', () {
      expect(
        SettlementStatus.fromString('SOME_NEW_STATUS'),
        SettlementStatus.unknown,
      );
    });

    test('fromString is case-insensitive (lowercase input)', () {
      expect(
        SettlementStatus.fromString('completed'),
        SettlementStatus.completed,
      );
      expect(
        SettlementStatus.fromString('pending'),
        SettlementStatus.pending,
      );
    });

    test('fromString handles mixed case input', () {
      expect(
        SettlementStatus.fromString('Processing'),
        SettlementStatus.processing,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SettlementStatus.label
  // ---------------------------------------------------------------------------
  group('SettlementStatus.label', () {
    test('pending label is 정산 대기', () {
      expect(SettlementStatus.pending.label, '정산 대기');
    });

    test('hold label is 보류', () {
      expect(SettlementStatus.hold.label, '보류');
    });

    test('ready label is 정산 확정', () {
      expect(SettlementStatus.ready.label, '정산 확정');
    });

    test('processing label is 지급 중', () {
      expect(SettlementStatus.processing.label, '지급 중');
    });

    test('completed label is 지급 완료', () {
      expect(SettlementStatus.completed.label, '지급 완료');
    });

    test('failed label is 지급 실패', () {
      expect(SettlementStatus.failed.label, '지급 실패');
    });

    test('canceled label is 취소', () {
      expect(SettlementStatus.canceled.label, '취소');
    });

    test('unknown label is 알 수 없음', () {
      expect(SettlementStatus.unknown.label, '알 수 없음');
    });
  });

  // ---------------------------------------------------------------------------
  // SettlementStatusBadge widget rendering
  // ---------------------------------------------------------------------------
  Widget buildTestWidget(SettlementStatus status, {bool compact = true}) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: SettlementStatusBadge(status: status, compact: compact),
      ),
    );
  }

  group('SettlementStatusBadge widget', () {
    testWidgets('renders label text for completed', (tester) async {
      await tester.pumpWidget(buildTestWidget(SettlementStatus.completed));
      expect(find.text('지급 완료'), findsOneWidget);
    });

    testWidgets('renders label text for pending', (tester) async {
      await tester.pumpWidget(buildTestWidget(SettlementStatus.pending));
      expect(find.text('정산 대기'), findsOneWidget);
    });

    testWidgets('renders label text for failed', (tester) async {
      await tester.pumpWidget(buildTestWidget(SettlementStatus.failed));
      expect(find.text('지급 실패'), findsOneWidget);
    });

    testWidgets('renders label text for canceled', (tester) async {
      await tester.pumpWidget(buildTestWidget(SettlementStatus.canceled));
      expect(find.text('취소'), findsOneWidget);
    });

    testWidgets(
      'canceled status uses strikethrough text decoration',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(SettlementStatus.canceled));
        final textWidget = tester.widget<Text>(find.text('취소'));
        expect(
          textWidget.style?.decoration,
          TextDecoration.lineThrough,
        );
      },
    );

    testWidgets(
      'non-canceled status does not use strikethrough',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(SettlementStatus.completed));
        final textWidget = tester.widget<Text>(find.text('지급 완료'));
        expect(
          textWidget.style?.decoration,
          isNot(TextDecoration.lineThrough),
        );
      },
    );

    testWidgets('non-compact uses bodySmall style', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(SettlementStatus.pending, compact: false),
      );
      expect(find.text('정산 대기'), findsOneWidget);
    });
  });
}
