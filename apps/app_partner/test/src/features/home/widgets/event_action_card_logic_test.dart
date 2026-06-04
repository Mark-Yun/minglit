import 'package:app_partner/src/logic/event_operation_phase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Event _makeEvent({
  required String id,
  required DateTime startTime,
  required DateTime endTime,
}) {
  final now = DateTime.now();
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
  // All times are relative to DateTime.now() so tests remain deterministic
  // regardless of when they run. We use large offsets (hours) to avoid
  // sub-second boundary flicker.

  group('getEventPhase', () {
    test('returns recruiting when start is more than 7 days away', () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'e1',
        startTime: now.add(const Duration(days: 8)),
        endTime: now.add(const Duration(days: 8, hours: 2)),
      );
      expect(getEventPhase(event), EventPhase.recruiting);
    });

    test('returns checkinReady when start is 90 minutes away', () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'e2',
        startTime: now.add(const Duration(minutes: 90)),
        endTime: now.add(const Duration(hours: 4)),
      );
      expect(getEventPhase(event), EventPhase.checkinReady);
    });

    test('returns preStart when start is inside T-7 but before T-2h', () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'e2b',
        startTime: now.add(const Duration(days: 3)),
        endTime: now.add(const Duration(days: 3, hours: 2)),
      );
      expect(getEventPhase(event), EventPhase.preStart);
    });

    test(
      'returns live when start has passed by 30 minutes and not yet ended',
      () {
        final now = DateTime.now();
        final event = _makeEvent(
          id: 'e3',
          startTime: now.subtract(const Duration(minutes: 30)),
          endTime: now.add(const Duration(hours: 2)),
        );
        expect(getEventPhase(event), EventPhase.live);
      },
    );

    test('returns ended when end time has passed by 2 hours', () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'e4',
        startTime: now.subtract(const Duration(hours: 4)),
        endTime: now.subtract(const Duration(hours: 2)),
      );
      expect(getEventPhase(event), EventPhase.ended);
    });

    test(
      'returns checkinReady when start is inside backend active window',
      () {
        final now = DateTime.now();
        final event = _makeEvent(
          id: 'e5',
          startTime: now.add(const Duration(minutes: 90)),
          endTime: now.add(const Duration(hours: 5)),
        );
        expect(getEventPhase(event), EventPhase.checkinReady);
      },
    );
  });

  group('selectPrimaryEvent', () {
    test('returns live event when one is present', () {
      final now = DateTime.now();
      final live = _makeEvent(
        id: 'live',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(hours: 2)),
      );
      final recruiting = _makeEvent(
        id: 'recruiting',
        startTime: now.add(const Duration(hours: 8)),
        endTime: now.add(const Duration(hours: 10)),
      );
      final result = selectPrimaryEvent([live, recruiting]);
      expect(result?.id, 'live');
    });

    test('returns checkin-ready event when no live event exists', () {
      final now = DateTime.now();
      final checkinReady = _makeEvent(
        id: 'checkin-ready',
        startTime: now.add(const Duration(minutes: 20)),
        endTime: now.add(const Duration(hours: 4)),
      );
      final recruiting = _makeEvent(
        id: 'recruiting',
        startTime: now.add(const Duration(days: 8)),
        endTime: now.add(const Duration(days: 8, hours: 2)),
      );
      final result = selectPrimaryEvent([checkinReady, recruiting]);
      expect(result?.id, 'checkin-ready');
    });

    test('returns ended event within 24 hours when no live or preparing', () {
      final now = DateTime.now();
      final ended = _makeEvent(
        id: 'ended',
        startTime: now.subtract(const Duration(hours: 4)),
        endTime: now.subtract(const Duration(hours: 2)),
      );
      final recruiting = _makeEvent(
        id: 'recruiting',
        startTime: now.add(const Duration(days: 8)),
        endTime: now.add(const Duration(days: 8, hours: 2)),
      );
      final result = selectPrimaryEvent([ended, recruiting]);
      expect(result?.id, 'ended');
    });

    test('returns earliest recruiting event when no higher-priority event', () {
      final now = DateTime.now();
      final far = _makeEvent(
        id: 'far',
        startTime: now.add(const Duration(days: 10)),
        endTime: now.add(const Duration(days: 10, hours: 2)),
      );
      final near = _makeEvent(
        id: 'near',
        startTime: now.add(const Duration(days: 8)),
        endTime: now.add(const Duration(days: 8, hours: 2)),
      );
      final result = selectPrimaryEvent([far, near]);
      expect(result?.id, 'near');
    });

    test('returns null when event list is empty', () {
      final result = selectPrimaryEvent([]);
      expect(result, isNull);
    });

    test('excludes ended events older than 24 hours', () {
      final now = DateTime.now();
      final oldEnded = _makeEvent(
        id: 'old_ended',
        startTime: now.subtract(const Duration(hours: 30)),
        endTime: now.subtract(const Duration(hours: 26)),
      );
      final result = selectPrimaryEvent([oldEnded]);
      expect(result, isNull);
    });
  });

  group('isCheckinActionEnabled', () {
    test('returns false before backend active window', () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'early',
        startTime: now.add(const Duration(hours: 3)),
        endTime: now.add(const Duration(hours: 5)),
      );

      expect(isCheckinActionEnabled(event), isFalse);
    });

    test('returns true within 2 hours before start', () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'ready',
        startTime: now.add(const Duration(minutes: 90)),
        endTime: now.add(const Duration(hours: 3)),
      );

      expect(isCheckinActionEnabled(event), isTrue);
    });

    test('returns true for live events', () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'live',
        startTime: now.subtract(const Duration(minutes: 10)),
        endTime: now.add(const Duration(hours: 2)),
      );

      expect(isCheckinActionEnabled(event), isTrue);
    });

    test('returns false after event end', () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'ended',
        startTime: now.subtract(const Duration(hours: 3)),
        endTime: now.subtract(const Duration(hours: 1)),
      );

      expect(isCheckinActionEnabled(event), isFalse);
    });
  });
}
