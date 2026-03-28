import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/utils/refund_calculator.dart';

void main() {
  group('RefundCalculator binary policy', () {
    const amount = 10000;
    final now = DateTime(2026, 3, 16, 12);

    test('within grace period → full refund', () {
      final paidAt = now.subtract(const Duration(hours: 1));
      final eventStart = now.add(const Duration(days: 3));
      final result = RefundCalculator.calculate(
        eventStartTime: eventStart,
        paymentAmount: amount,
        paidAt: paidAt,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );
      expect(result.refundPercentage, 100);
      expect(result.refundAmount, amount);
      expect(result.feeAmount, 0);
    });

    test('within cutoff days → full refund', () {
      final paidAt = now.subtract(const Duration(hours: 5));
      final eventStart = now.add(const Duration(days: 10));
      final result = RefundCalculator.calculate(
        eventStartTime: eventStart,
        paymentAmount: amount,
        paidAt: paidAt,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );
      expect(result.refundPercentage, 100);
      expect(result.refundAmount, amount);
      expect(result.feeAmount, 0);
    });

    test('both conditions fail → no refund', () {
      final paidAt = now.subtract(const Duration(hours: 5));
      final eventStart = now.add(const Duration(days: 3));
      final result = RefundCalculator.calculate(
        eventStartTime: eventStart,
        paymentAmount: amount,
        paidAt: paidAt,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );
      expect(result.refundPercentage, 0);
      expect(result.refundAmount, 0);
      expect(result.feeAmount, amount);
    });

    test('paidAt null + within cutoff → full refund', () {
      final eventStart = now.add(const Duration(days: 10));
      final result = RefundCalculator.calculate(
        eventStartTime: eventStart,
        paymentAmount: amount,
        paidAt: null,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );
      expect(result.refundPercentage, 100);
      expect(result.refundAmount, amount);
    });

    test('paidAt null + outside cutoff → no refund', () {
      final eventStart = now.add(const Duration(days: 3));
      final result = RefundCalculator.calculate(
        eventStartTime: eventStart,
        paymentAmount: amount,
        paidAt: null,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );
      expect(result.refundPercentage, 0);
      expect(result.refundAmount, 0);
    });

    test('exactly at grace period boundary → full refund', () {
      final paidAt = now.subtract(const Duration(hours: 2));
      final eventStart = now.add(const Duration(days: 3));
      final result = RefundCalculator.calculate(
        eventStartTime: eventStart,
        paymentAmount: amount,
        paidAt: paidAt,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );
      expect(result.refundPercentage, 100);
    });

    test('exactly at cutoff boundary → full refund', () {
      final paidAt = now.subtract(const Duration(hours: 5));
      final eventStart = now.add(const Duration(days: 7));
      final result = RefundCalculator.calculate(
        eventStartTime: eventStart,
        paymentAmount: amount,
        paidAt: paidAt,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );
      expect(result.refundPercentage, 100);
    });

    test('zero payment amount returns zero amounts', () {
      final eventStart = now.add(const Duration(days: 10));
      final result = RefundCalculator.calculate(
        eventStartTime: eventStart,
        paymentAmount: 0,
        paidAt: null,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );
      expect(result.refundAmount, 0);
      expect(result.feeAmount, 0);
    });
  });
}
