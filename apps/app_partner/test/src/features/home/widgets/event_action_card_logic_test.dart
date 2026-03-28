import 'package:app_partner/src/features/home/widgets/event_action_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Event _makeEvent({
  required String id,
  required DateTime startTime,
  required DateTime endTime,
}) {
  final now = DateTime(2026, 3, 28, 12);
  return Event(
    id: id,
    partyId: 'p1',
    startTime: startTime,
    endTime: endTime,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // Fixed reference point: 2026-03-28 12:00:00
  final ref = DateTime(2026, 3, 28, 12);

  group('getEventPhase', () {
    test('returns recruiting when start is more than 3 hours away', () {
      final event = _makeEvent(
        id: 'e1',
        startTime: ref.add(const Duration(hours: 4)),
        endTime: ref.add(const Duration(hours: 6)),
      );
      expect(getEventPhase(event, now: ref), EventPhase.recruiting);
    });

    test('returns preparing when start is 2 hours away', () {
      final event = _makeEvent(
        id: 'e2',
        startTime: ref.add(const Duration(hours: 2)),
        endTime: ref.add(const Duration(hours: 4)),
      );
      expect(getEventPhase(event, now: ref), EventPhase.preparing);
    });

    test('returns live when start has passed by 30 minutes and not yet ended',
        () {
      final event = _makeEvent(
        id: 'e3',
        startTime: ref.subtract(const Duration(minutes: 30)),
        endTime: ref.add(const Duration(hours: 2)),
      );
      expect(getEventPhase(event, now: ref), EventPhase.live);
    });

    test('returns ended when end time has passed by 2 hours', () {
      final event = _makeEvent(
        id: 'e4',
        startTime: ref.subtract(const Duration(hours: 4)),
        endTime: ref.subtract(const Duration(hours: 2)),
      );
      expect(getEventPhase(event, now: ref), EventPhase.ended);
    });

    test('returns preparing when start is exactly 3 hours away (boundary)', () {
      final event = _makeEvent(
        id: 'e5',
        startTime: ref.add(const Duration(hours: 3)),
        endTime: ref.add(const Duration(hours: 5)),
      );
      // Exactly 180 minutes → not > 180 → preparing
      expect(getEventPhase(event, now: ref), EventPhase.preparing);
    });
  });

  group('selectPrimaryEvent', () {
    test('returns live event when one is present', () {
      final live = _makeEvent(
        id: 'live',
        startTime: ref.subtract(const Duration(minutes: 30)),
        endTime: ref.add(const Duration(hours: 2)),
      );
      final recruiting = _makeEvent(
        id: 'recruiting',
        startTime: ref.add(const Duration(hours: 5)),
        endTime: ref.add(const Duration(hours: 7)),
      );
      final result = selectPrimaryEvent([live, recruiting], now: ref);
      expect(result?.id, 'live');
    });

    test('returns preparing event when no live event exists', () {
      final preparing = _makeEvent(
        id: 'preparing',
        startTime: ref.add(const Duration(hours: 2)),
        endTime: ref.add(const Duration(hours: 4)),
      );
      final recruiting = _makeEvent(
        id: 'recruiting',
        startTime: ref.add(const Duration(hours: 6)),
        endTime: ref.add(const Duration(hours: 8)),
      );
      final result = selectPrimaryEvent([preparing, recruiting], now: ref);
      expect(result?.id, 'preparing');
    });

    test('returns ended event within 24 hours when no live or preparing', () {
      final ended = _makeEvent(
        id: 'ended',
        startTime: ref.subtract(const Duration(hours: 4)),
        endTime: ref.subtract(const Duration(hours: 2)),
      );
      final recruiting = _makeEvent(
        id: 'recruiting',
        startTime: ref.add(const Duration(hours: 6)),
        endTime: ref.add(const Duration(hours: 8)),
      );
      final result = selectPrimaryEvent([ended, recruiting], now: ref);
      expect(result?.id, 'ended');
    });

    test('returns earliest recruiting event when no higher-priority event', () {
      final far = _makeEvent(
        id: 'far',
        startTime: ref.add(const Duration(hours: 10)),
        endTime: ref.add(const Duration(hours: 12)),
      );
      final near = _makeEvent(
        id: 'near',
        startTime: ref.add(const Duration(hours: 5)),
        endTime: ref.add(const Duration(hours: 7)),
      );
      final result = selectPrimaryEvent([far, near], now: ref);
      expect(result?.id, 'near');
    });

    test('returns null when event list is empty', () {
      final result = selectPrimaryEvent([], now: ref);
      expect(result, isNull);
    });

    test('excludes ended events older than 24 hours', () {
      final oldEnded = _makeEvent(
        id: 'old_ended',
        startTime: ref.subtract(const Duration(hours: 30)),
        endTime: ref.subtract(const Duration(hours: 26)),
      );
      final result = selectPrimaryEvent([oldEnded], now: ref);
      expect(result, isNull);
    });
  });
}
