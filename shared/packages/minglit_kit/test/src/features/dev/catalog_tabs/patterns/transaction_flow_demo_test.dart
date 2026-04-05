import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/patterns/transaction_flow_demo.dart';

/// Wraps [widget] in a [MaterialApp] + [Scaffold] for pump.
Widget _wrap(Widget widget) {
  return MaterialApp(home: Scaffold(body: widget));
}

void main() {
  group('TransactionFlowDemoPage', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));
      expect(find.byType(TransactionFlowDemoPage), findsOneWidget);
    });

    testWidgets('shows payment flow section header', (tester) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));
      expect(find.text('결제 플로우'), findsOneWidget);
    });

    testWidgets('shows refund flow section header', (tester) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));
      expect(find.text('환불 플로우'), findsOneWidget);
    });

    testWidgets('shows payment SegmentedButton with four segments', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

      expect(find.text('확인'), findsOneWidget);
      expect(find.text('처리 중'), findsAtLeastNWidgets(1));
      expect(find.text('성공'), findsOneWidget);
      expect(find.text('실패'), findsOneWidget);
    });

    testWidgets('shows refund SegmentedButton with four segments', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

      expect(find.text('요청'), findsOneWidget);
      expect(find.text('계산 중'), findsOneWidget);
      expect(find.text('완료'), findsOneWidget);
    });
  });

  group('PaymentFlowState panels', () {
    testWidgets('confirm state renders order summary and 결제하기 button', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));
      // Default state is confirm.
      expect(find.text('주문 요약'), findsOneWidget);
      expect(find.text('결제하기'), findsOneWidget);
      expect(find.text('밍글릿 봄 파티'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'processing state renders CircularProgressIndicator and label',
      (tester) async {
        await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

        // Tap "처리 중" segment in payment section (first SegmentedButton).
        final processingSegments = find.text('처리 중');
        await tester.tap(processingSegments.first);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
        expect(find.text('결제 처리 중...'), findsOneWidget);
      },
    );

    testWidgets('success state renders check_circle icon and 결제 완료 text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

      await tester.tap(find.text('성공'));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
      expect(find.text('결제 완료'), findsOneWidget);
    });

    testWidgets('failure state renders cancel icon and 다시 시도 button', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

      await tester.tap(find.text('실패'));
      await tester.pump();

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.text('결제 실패'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });
  });

  group('RefundFlowState panels', () {
    testWidgets('request state renders 취소 요청 button', (tester) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));
      // Default refund state is request.
      expect(find.text('취소 요청'), findsAtLeastNWidgets(1));
      expect(find.text('TKT-00123'), findsOneWidget);
    });

    testWidgets('calculating state renders spinner and label', (tester) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

      await tester.tap(find.text('계산 중'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.text('환불 금액 계산 중'), findsOneWidget);
    });

    testWidgets('processing state renders spinner and label', (tester) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

      // Tap "처리 중" in refund section — it is the second occurrence.
      final processingSegments = find.text('처리 중');
      await tester.tap(processingSegments.last);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.text('환불 처리 중'), findsOneWidget);
    });

    testWidgets('complete state renders check icon and 환불 완료 text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

      // "완료" appears only in the refund SegmentedButton.
      await tester.tap(find.text('완료'));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
      expect(find.text('환불 완료'), findsOneWidget);
      expect(find.text('₩30,000'), findsAtLeastNWidgets(1));
    });
  });

  group('State transitions', () {
    testWidgets('payment flow cycles through all states without error', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

      // confirm → processing
      await tester.tap(find.text('처리 중').first);
      await tester.pump();
      expect(find.text('결제 처리 중...'), findsOneWidget);

      // processing → success
      await tester.tap(find.text('성공'));
      await tester.pump();
      expect(find.text('결제 완료'), findsOneWidget);

      // success → failure
      await tester.tap(find.text('실패'));
      await tester.pump();
      expect(find.text('결제 실패'), findsOneWidget);

      // failure → confirm
      await tester.tap(find.text('확인'));
      await tester.pump();
      expect(find.text('주문 요약'), findsOneWidget);
    });

    testWidgets('refund flow cycles through all states without error', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TransactionFlowDemoPage()));

      // request → calculating
      await tester.tap(find.text('계산 중'));
      await tester.pump();
      expect(find.text('환불 금액 계산 중'), findsOneWidget);

      // calculating → processing
      await tester.tap(find.text('처리 중').last);
      await tester.pump();
      expect(find.text('환불 처리 중'), findsOneWidget);

      // processing → complete
      await tester.tap(find.text('완료'));
      await tester.pump();
      expect(find.text('환불 완료'), findsOneWidget);

      // complete → request
      await tester.tap(find.text('요청'));
      await tester.pump();
      expect(find.text('취소 요청'), findsAtLeastNWidgets(1));
    });
  });
}
