import 'package:app_partner/src/features/home/widgets/event_action_card.dart';
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
    test('returns recruiting when start is more than 3 hours away', () {
      // Use 5 hours to avoid sub-second drift between test setup and
      // DateTime.now() inside getEventPhase causing inHours to truncate to 3.
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'e1',
        startTime: now.add(const Duration(hours: 5)),
        endTime: now.add(const Duration(hours: 7)),
      );
      expect(getEventPhase(event), EventPhase.recruiting);
    });

    test('returns preparing when start is 2 hours away', () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'e2',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 4)),
      );
      expect(getEventPhase(event), EventPhase.preparing);
    });

    test('returns live when start has passed by 30 minutes and not yet ended',
        () {
      final now = DateTime.now();
      final event = _makeEvent(
        id: 'e3',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(hours: 2)),
      );
      expect(getEventPhase(event), EventPhase.live);
    });

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
        'returns preparing when start is exactly 3 hours away (boundary: inHours == 3)',
        () {
      final now = DateTime.now();
      // inHours truncates: 3h0m → inHours == 3 → <= 3 → preparing
      final event = _makeEvent(
        id: 'e5',
        startTime: now.add(const Duration(hours: 3)),
        endTime: now.add(const Duration(hours: 5)),
      );
      expect(getEventPhase(event), EventPhase.preparing);
    });
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

    test('returns preparing event when no live event exists', () {
      final now = DateTime.now();
      final preparing = _makeEvent(
        id: 'preparing',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 4)),
      );
      final recruiting = _makeEvent(
        id: 'recruiting',
        startTime: now.add(const Duration(hours: 8)),
        endTime: now.add(const Duration(hours: 10)),
      );
      final result = selectPrimaryEvent([preparing, recruiting]);
      expect(result?.id, 'preparing');
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
        startTime: now.add(const Duration(hours: 8)),
        endTime: now.add(const Duration(hours: 10)),
      );
      final result = selectPrimaryEvent([ended, recruiting]);
      expect(result?.id, 'ended');
    });

    test('returns earliest recruiting event when no higher-priority event', () {
      final now = DateTime.now();
      final far = _makeEvent(
        id: 'far',
        startTime: now.add(const Duration(hours: 10)),
        endTime: now.add(const Duration(hours: 12)),
      );
      final near = _makeEvent(
        id: 'near',
        startTime: now.add(const Duration(hours: 5)),
        endTime: now.add(const Duration(hours: 7)),
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
}
