import 'package:app_user/src/features/ticket/logic/boarding_pass_status.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests for BoardingPassStatus determination logic.
// Covers P1 cases from test-plan.md Layer 2.

void main() {
  group('boardingPassStatus', () {
    // Pin a reference "now" to make tests deterministic.
    final now = DateTime(2026, 4, 15, 12); // Wednesday 2026-04-15 12:00

    test('오늘 이벤트 (startTime이 오늘) → BOARDING', () {
      final todayMorning = DateTime(2026, 4, 15, 9);
      final todayEvening = DateTime(2026, 4, 15, 21);

      expect(
        boardingPassStatus(todayMorning, now: now),
        BoardingPassStatus.boarding,
      );
      expect(
        boardingPassStatus(todayEvening, now: now),
        BoardingPassStatus.boarding,
      );
    });

    test('미래 이벤트 (startTime이 내일 이후) → CONFIRMED', () {
      final tomorrow = DateTime(2026, 4, 16, 19);
      final nextWeek = DateTime(2026, 4, 22, 10);

      expect(
        boardingPassStatus(tomorrow, now: now),
        BoardingPassStatus.confirmed,
      );
      expect(
        boardingPassStatus(nextWeek, now: now),
        BoardingPassStatus.confirmed,
      );
    });

    test('지난 이벤트 (startTime이 어제 이전) → USED', () {
      final yesterday = DateTime(2026, 4, 14, 19);
      final lastWeek = DateTime(2026, 4, 8, 10);

      expect(
        boardingPassStatus(yesterday, now: now),
        BoardingPassStatus.used,
      );
      expect(
        boardingPassStatus(lastWeek, now: now),
        BoardingPassStatus.used,
      );
    });

    test('오늘 자정 경계 — 23:59 시작 이벤트가 BOARDING으로 분류', () {
      // 23:59 today must be BOARDING, not CONFIRMED
      final lateTonight = DateTime(2026, 4, 15, 23, 59);

      expect(
        boardingPassStatus(lateTonight, now: now),
        BoardingPassStatus.boarding,
      );
    });

    test('오늘 자정 00:00 — BOARDING 경계의 시작', () {
      final midnight = DateTime(2026, 4, 15);

      expect(
        boardingPassStatus(midnight, now: now),
        BoardingPassStatus.boarding,
      );
    });

    test('now 파라미터 미지정 시 DateTime.now() 기준으로 동작', () {
      // Cannot pin the exact result, but must not throw
      expect(
        () => boardingPassStatus(DateTime.now()),
        returnsNormally,
      );
    });
  });

  // Fix #2374 regression guard: semanticLabel 접근성 레이블 검증
  group('BoardingPassStatus.semanticLabel', () {
    test('boarding → "입장 가능"', () {
      expect(BoardingPassStatus.boarding.semanticLabel, '입장 가능');
    });

    test('confirmed → "예약 확정"', () {
      expect(BoardingPassStatus.confirmed.semanticLabel, '예약 확정');
    });

    test('used → "사용 완료"', () {
      expect(BoardingPassStatus.used.semanticLabel, '사용 완료');
    });
  });
}
