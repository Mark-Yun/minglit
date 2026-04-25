import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_controller.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DataController extends ManualCheckinController {
  _DataController(this._participants, {this.checkinResult = 'success'});
  final List<CheckinParticipant> _participants;
  final String checkinResult;

  @override
  Future<List<CheckinParticipant>> build(String eventId) async => _participants;

  @override
  Future<String> checkin(String ticketId) async {
    if (checkinResult == 'success') {
      state = state.whenData(
        (list) => list.map((p) {
          if (p.ticketId != ticketId) return p;
          return p.copyWith(status: 'checked_in');
        }).toList(),
      );
    }
    return checkinResult;
  }
}

Widget _wrapSheet({
  required String eventId,
  required List<CheckinParticipant> participants,
  String checkinResult = 'success',
}) {
  return ProviderScope(
    overrides: [
      manualCheckinControllerProvider(eventId).overrideWith(
        () => _DataController(participants, checkinResult: checkinResult),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ManualCheckinSheet(eventId: eventId),
      ),
    ),
  );
}

const _participantA = CheckinParticipant(
  id: 'ep-1',
  ticketId: 'tk-1',
  name: '김민지',
  phoneLast4: '1234',
  status: 'ticket_issued',
);

const _participantB = CheckinParticipant(
  id: 'ep-2',
  ticketId: 'tk-2',
  name: '박재훈',
  phoneLast4: '5678',
  status: 'checked_in',
);

void main() {
  group('ManualCheckinSheet', () {
    testWidgets('참가자 있음 — 섹션 헤더 표시', (tester) async {
      await tester.pumpWidget(
        _wrapSheet(
          eventId: 'event-1',
          participants: [_participantA, _participantB],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('미체크인 (1명)'), findsOneWidget);
      expect(find.text('체크인 완료 (1명)'), findsOneWidget);
    });

    testWidgets('빈 참가자 — "참가자가 없습니다" 표시', (tester) async {
      await tester.pumpWidget(
        _wrapSheet(eventId: 'event-empty', participants: []),
      );
      await tester.pumpAndSettle();

      expect(find.text('참가자가 없습니다'), findsOneWidget);
    });

    testWidgets('이름 검색 — "박" 입력 시 박재훈만 표시', (tester) async {
      await tester.pumpWidget(
        _wrapSheet(
          eventId: 'event-1',
          participants: [_participantA, _participantB],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '박');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('박재훈'), findsOneWidget);
      expect(find.text('김민지'), findsNothing);
    });

    testWidgets('전화 뒷자리 검색 — "1234" 입력 시 김민지만 표시', (tester) async {
      await tester.pumpWidget(
        _wrapSheet(
          eventId: 'event-1',
          participants: [_participantA, _participantB],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('김민지'), findsOneWidget);
      expect(find.text('박재훈'), findsNothing);
    });

    testWidgets('체크인 버튼 탭 — 미체크인 참가자 이동', (tester) async {
      await tester.pumpWidget(
        _wrapSheet(
          eventId: 'event-1',
          participants: [_participantA],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('미체크인 (1명)'), findsOneWidget);
      await tester.tap(find.text('체크인'));
      await tester.pumpAndSettle();

      expect(find.text('미체크인 (0명)'), findsNothing);
      expect(find.text('체크인 완료 (1명)'), findsOneWidget);
    });

    testWidgets('완료 버튼은 비활성화 — onPressed null', (tester) async {
      await tester.pumpWidget(
        _wrapSheet(
          eventId: 'event-1',
          participants: [_participantB],
        ),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(btn.onPressed, isNull);
    });
  });
}
