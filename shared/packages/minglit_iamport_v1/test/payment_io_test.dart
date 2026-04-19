import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_iamport_v1/src/implementation/payment_io.dart';

// Fix #1535 회귀 테스트: PaymentServiceImpl을 서브클래스화해
// IamportPayment 대신 back-button 시나리오를 주입한다.
// onResult를 호출하지 않고 즉시 pop — Completer가 callback 없이 pending 상태로
// 남는 상황을 재현하여 `if (!completer.isCompleted)` 가드가 동작하는지 검증한다.
class _BackButtonPaymentService extends PaymentServiceImpl {
  @override
  Widget buildPaymentPage({
    required String userCode,
    required Map<String, dynamic> data,
    required void Function(Map<String, String>) onResult,
  }) {
    return Builder(builder: (ctx) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(ctx)) Navigator.of(ctx).pop();
      });
      return const SizedBox.shrink();
    });
  }
}

void main() {
  group('PaymentServiceImpl (Fix #1535)', () {
    testWidgets(
      'requestPayment returns null when back button pressed without callback',
      (tester) async {
        final service = _BackButtonPaymentService();
        Future<String?>? futureResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  futureResult = service.requestPayment(
                    context: ctx,
                    userCode: 'test_merchant_code',
                    data: const {'merchant_uid': 'test_order_1'},
                  );
                },
                child: const Text('결제하기'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('결제하기'));
        await tester.pumpAndSettle();

        expect(futureResult, isNotNull,
            reason: 'requestPayment must have been called');
        // Fix #1535 핵심 assertion: callback 없이 pop 시 null을 반환해야 한다.
        // payment_io.dart의 `if (!completer.isCompleted) completer.complete(null)` 가드를
        // 삭제하면 이 테스트가 타임아웃으로 실패해 회귀를 차단한다.
        expect(
          await futureResult,
          isNull,
          reason: 'back navigation without payment callback must resolve to null, not hang',
        );
      },
    );
  });
}
