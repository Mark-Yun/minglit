// CUJ tests — event-operation / partner-qr-checkin-ux (app_partner)
//
// 대응 spec: docs/features/event-operation/partner-qr-checkin-ux/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// Fix #2564: event-operation 카테고리 CUJ integration test 전무 해소 (수동 체크인)

import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_controller.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Fake controller for isolation (no Supabase RPC in test)
// ---------------------------------------------------------------------------

class _FakeManualCheckinController extends ManualCheckinController {
  final List<CheckinParticipant> _participants;
  _FakeManualCheckinController(this._participants);

  @override
  Future<List<CheckinParticipant>> build(String eventId) async => _participants;

  @override
  Future<String> checkin(String ticketId) async => 'success';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CheckinParticipant _makeParticipant({
  String id = 'p-1',
  String name = '김민수',
  String phoneLast4 = '1234',
  bool checked = false,
}) => CheckinParticipant(
  id: id,
  ticketId: 'ticket-$id',
  name: name,
  phoneLast4: phoneLast4,
  status: checked ? 'checked_in' : 'ticket_issued',
);

const _testEventId = 'event-test-1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 3-1: QR 인식 실패 시 수동 체크인 진입 (FR-9)
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '수동 체크인 시트 진입 + 참가자 목록 표시', () {
    cujCase(
      'happy: 참가자 있을 때 → 헤더 + 이름 목록 표시',
      app: const ManualCheckinSheet(eventId: _testEventId),
      overrides: () => [
        manualCheckinControllerProvider(_testEventId).overrideWith(
          () => _FakeManualCheckinController([
            _makeParticipant(name: '김민수'),
            _makeParticipant(id: 'p-2', name: '이지원', phoneLast4: '5678'),
          ]),
        ),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('수동 체크인'), findsOneWidget);
        expect(find.text('김민수'), findsOneWidget);
        expect(find.text('이지원'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 참가자 없을 때 → 빈 상태 안내 표시',
      app: const ManualCheckinSheet(eventId: _testEventId),
      overrides: () => [
        manualCheckinControllerProvider(_testEventId).overrideWith(
          () => _FakeManualCheckinController([]),
        ),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('수동 체크인'), findsOneWidget);
        expect(find.text('참가자가 없습니다'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 수동 체크인 토글로 처리 (FR-10)
  // ---------------------------------------------------------------------------

  cujGroup('3-2', '수동 체크인 처리 — 체크인 버튼 표시', () {
    cujCase(
      'happy: 미체크인 참가자 → 체크인 버튼 표시',
      app: const ManualCheckinSheet(eventId: _testEventId),
      overrides: () => [
        manualCheckinControllerProvider(_testEventId).overrideWith(
          () => _FakeManualCheckinController([
            _makeParticipant(name: '박서연', checked: false),
          ]),
        ),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('박서연'), findsOneWidget);
        expect(find.text('체크인'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 이미 체크인된 참가자 → 완료 버튼 표시',
      app: const ManualCheckinSheet(eventId: _testEventId),
      overrides: () => [
        manualCheckinControllerProvider(_testEventId).overrideWith(
          () => _FakeManualCheckinController([
            _makeParticipant(name: '최준호', checked: true),
          ]),
        ),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('최준호'), findsOneWidget);
        // 이미 체크인된 참가자는 '완료' 버튼 표시 (라인 418)
        expect(find.text('완료'), findsOneWidget);
        // '체크인' 버튼은 없음 (미체크인 참가자 없음)
        expect(find.text('체크인'), findsNothing);
      },
    );
  });
}
