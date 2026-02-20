import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/utils/refund_calculator.dart';

void main() {
  group('RefundCalculator - edge cases', () {
    test('exactly 7 days returns 100% refund', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(const Duration(days: 7)),
        paymentAmount: 10000,
        now: now,
      );

      expect(result.refundPercentage, 100);
      expect(result.refundAmount, 10000);
      expect(result.feeAmount, 0);
    });

    test('exactly 3 days returns 80% refund', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(const Duration(days: 3)),
        paymentAmount: 10000,
        now: now,
      );

      expect(result.refundPercentage, 80);
      expect(result.refundAmount, 8000);
      expect(result.feeAmount, 2000);
    });

    test('exactly 1 day returns 50% refund', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(const Duration(days: 1)),
        paymentAmount: 10000,
        now: now,
      );

      expect(result.refundPercentage, 50);
      expect(result.refundAmount, 5000);
      expect(result.feeAmount, 5000);
    });

    test('event already started returns 0% refund', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.subtract(const Duration(hours: 1)),
        paymentAmount: 10000,
        now: now,
      );

      expect(result.refundPercentage, 0);
      expect(result.refundAmount, 0);
      expect(result.feeAmount, 10000);
    });

    test('zero payment amount returns zero amounts', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(const Duration(days: 10)),
        paymentAmount: 0,
        now: now,
      );

      expect(result.refundAmount, 0);
      expect(result.feeAmount, 0);
    });

    test('large payment amount calculates correctly', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(const Duration(days: 5)),
        paymentAmount: 1000000,
        now: now,
      );

      expect(result.refundPercentage, 80);
      expect(result.refundAmount, 800000);
      expect(result.feeAmount, 200000);
    });

    test('23 hours 59 minutes returns 0% refund', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(
          const Duration(hours: 23, minutes: 59),
        ),
        paymentAmount: 10000,
        now: now,
      );

      expect(result.refundPercentage, 0);
      expect(result.refundAmount, 0);
      expect(result.feeAmount, 10000);
    });
  });
}
