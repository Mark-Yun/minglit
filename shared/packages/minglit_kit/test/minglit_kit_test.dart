import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/utils/age_util.dart';
import 'package:minglit_kit/src/utils/refund_calculator.dart';
import 'package:minglit_kit/src/utils/ticket_crypto.dart';

void main() {
  group('RefundCalculator', () {
    test('이벤트 7일 이상 전이면 100% 환불 (cutoff 합격)', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(const Duration(days: 8)),
        paymentAmount: 10000,
        paidAt: null,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );

      expect(result.refundPercentage, 100);
      expect(result.refundAmount, 10000);
      expect(result.feeAmount, 0);
    });

    test('이벤트 5일 전 + paidAt 없음 → 환불 불가', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(const Duration(days: 5)),
        paymentAmount: 10000,
        paidAt: null,
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );

      expect(result.refundPercentage, 0);
      expect(result.refundAmount, 0);
      expect(result.feeAmount, 10000);
    });

    test('결제 후 1시간 이내 → 100% 환불 (grace period 합격)', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(const Duration(days: 2)),
        paymentAmount: 10000,
        paidAt: now.subtract(const Duration(hours: 1)),
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );

      expect(result.refundPercentage, 100);
      expect(result.refundAmount, 10000);
      expect(result.feeAmount, 0);
    });

    test('결제 후 3시간 + 이벤트 12시간 전 → 환불 불가', () {
      final now = DateTime(2026, 1, 1, 12);
      final result = RefundCalculator.calculate(
        eventStartTime: now.add(const Duration(hours: 12)),
        paymentAmount: 10000,
        paidAt: now.subtract(const Duration(hours: 3)),
        gracePeriodHours: 2,
        cutoffDays: 7,
        now: now,
      );

      expect(result.refundPercentage, 0);
      expect(result.refundAmount, 0);
      expect(result.feeAmount, 10000);
    });
  });

  group('AgeUtil', () {
    test('한국 나이 계산', () {
      final currentYear = DateTime.now().year;
      final birthYear = currentYear - 20;

      expect(AgeUtil.calculateKoreanAge(birthYear), 21);
    });

    test('만 나이 계산', () {
      final currentYear = DateTime.now().year;
      final birthYear = currentYear - 20;

      expect(AgeUtil.calculateManAge(birthYear), 20);
    });
  });

  group('TicketCrypto', () {
    test('서명 검증 성공', () async {
      final crypto = TicketCrypto();
      final keyPair = await crypto.generateKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      const payload = 'ticket:abc123';

      final signature = await crypto.sign(payload, keyPair);
      final verified = await crypto.verify(payload, signature, publicKey);

      expect(verified, isTrue);
    });

    test('서명 검증 실패', () async {
      final crypto = TicketCrypto();
      final keyPair = await crypto.generateKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      const payload = 'ticket:abc123';

      final signature = await crypto.sign(payload, keyPair);
      final verified = await crypto.verify(
        'ticket:wrong',
        signature,
        publicKey,
      );

      expect(verified, isFalse);
    });
  });
}
