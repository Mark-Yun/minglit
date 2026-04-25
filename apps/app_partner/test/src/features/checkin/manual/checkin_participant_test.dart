import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckinParticipant', () {
    test('fromJson — ticket_issued 상태', () {
      final p = CheckinParticipant.fromJson({
        'id': 'ep-1',
        'ticket_id': 'tk-1',
        'name': '김민지',
        'phone_last4': '1234',
        'status': 'ticket_issued',
        'checked_in_at': null,
      });

      expect(p.id, 'ep-1');
      expect(p.name, '김민지');
      expect(p.phoneLast4, '1234');
      expect(p.isCheckedIn, isFalse);
      expect(p.checkedInAt, isNull);
    });

    test('fromJson — checked_in 상태 + 시각', () {
      final p = CheckinParticipant.fromJson({
        'id': 'ep-2',
        'ticket_id': 'tk-2',
        'name': '박재훈',
        'phone_last4': '5678',
        'status': 'checked_in',
        'checked_in_at': '2026-04-24T10:30:00.000Z',
      });

      expect(p.isCheckedIn, isTrue);
      expect(p.checkedInAt, isNotNull);
      expect(p.checkedInAt!.year, 2026);
    });

    test('fromJson — phone_last4 null 허용', () {
      final p = CheckinParticipant.fromJson({
        'id': 'ep-3',
        'ticket_id': 'tk-3',
        'name': '이름 없음',
        'phone_last4': null,
        'status': 'ticket_issued',
        'checked_in_at': null,
      });

      expect(p.phoneLast4, '');
    });

    test('copyWith — status 업데이트', () {
      const original = CheckinParticipant(
        id: 'ep-1',
        ticketId: 'tk-1',
        name: '홍길동',
        phoneLast4: '0001',
        status: 'ticket_issued',
      );

      final updated = original.copyWith(status: 'checked_in');
      expect(updated.status, 'checked_in');
      expect(updated.id, original.id);
      expect(updated.name, original.name);
    });
  });
}
