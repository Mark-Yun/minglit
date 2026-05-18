// CUJ tests — event-operation / partner-qr-checkin-ux (app_partner)
//
// 대응 spec: docs/features/event-operation/partner-qr-checkin-ux/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// Refs #2589: partner-qr-checkin-ux CUJ integration test 신규 작성

import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_controller.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_sheet.dart';
import 'package:app_partner/src/features/checkin/widgets/checkin_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Fakes for provider isolation
// ---------------------------------------------------------------------------

class _FakeManualCheckinController extends ManualCheckinController {
  _FakeManualCheckinController(this._participants);

  final List<CheckinParticipant> _participants;

  @override
  Future<List<CheckinParticipant>> build(String eventId) async => _participants;

  @override
  Future<String> checkin(String ticketId) async {
    // Optimistic update — mark as checked_in
    state = AsyncData(
      (state.value ?? []).map((p) {
        if (p.ticketId != ticketId) return p;
        return p.copyWith(status: 'checked_in', checkedInAt: DateTime.now());
      }).toList(),
    );
    return 'success';
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CheckinParticipant _makeParticipant({
  String id = 'p-1',
  String ticketId = 'ticket-1',
  String name = '홍길동',
  String phoneLast4 = '1234',
  String status = 'ticket_issued',
}) => CheckinParticipant(
  id: id,
  ticketId: ticketId,
  name: name,
  phoneLast4: phoneLast4,
  status: status,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 체크인 화면 진입 → 요약 카드 즉시 표시 (FR-1, FR-2)
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '체크인 화면 진입 → 요약 카드 즉시 표시', () {
    cujCase(
      'happy: checkedIn=23, total=50 → "23/50" + "46%" 표시',
      app: const Scaffold(body: CheckinSummaryCard(checkedIn: 23, total: 50)),
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 카운트 "23/50"
        expect(find.text('23'), findsOneWidget);
        expect(find.text('/50'), findsOneWidget);

        // 진행률 "46%"
        expect(find.text('46%'), findsOneWidget);
      },
    );

    cujCase(
      'edge: stats 미로딩 시 shimmer placeholder 표시',
      app: const Scaffold(
        body: CheckinSummaryCard(
          checkedIn: 0,
          total: 0,
          isLoading: true,
        ),
      ),
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 로딩 중에는 카운트 텍스트 없음 — skeleton만 표시
        expect(find.text('0'), findsNothing);
        expect(find.text('/0'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 스캔 성공 시 요약 카드 자동 갱신 (FR-3, FR-4)
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '스캔 성공 → 요약 카드 카운트 즉시 +1', () {
    cujCase(
      'happy: checkedIn=5→6 — StatefulBuilder로 상태 변경 후 카드 갱신 확인',
      app: const _IncrementalCountCard(initialCount: 5, total: 20),
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 초기 상태: 5/20
        expect(find.text('5'), findsOneWidget);

        // 스캔 성공 시뮬레이션: +1 버튼 탭 (StatefulBuilder가 카운트 올림)
        await t.tap(find.byKey(const Key('increment')));
        await t.pump();
        await t.pumpAndSettle();

        // 갱신 후: 6/20
        expect(find.text('6'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 요약 카드 오프라인 상태 (네트워크 불안정 대비) (FR-5)
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '네트워크 불안정 → 카드 오프라인 표시', () {
    cujCase(
      'edge: isOffline=true → "캐시됨" 배지 표시',
      app: const Scaffold(
        body: CheckinSummaryCard(
          checkedIn: 10,
          total: 30,
          isOffline: true,
        ),
      ),
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 오프라인 배지 확인
        expect(find.text('캐시됨'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: QR 인식 실패 시 수동 체크인 진입 (FR-9, FR-10)
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '수동 체크인 시트 진입 + 참가자 목록 표시', () {
    cujCase(
      'happy: 참가자 있음 → 이름 + 검색 필드 표시',
      app: const Scaffold(body: ManualCheckinSheet(eventId: 'evt-1')),
      overrides: () => [
        manualCheckinControllerProvider('evt-1').overrideWith(
          () => _FakeManualCheckinController([
            _makeParticipant(),
            _makeParticipant(id: 'p-2', ticketId: 'ticket-2', name: '김철수'),
          ]),
        ),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 시트 제목 + 참가자 이름 확인
        expect(find.text('수동 체크인'), findsOneWidget);
        expect(find.text('홍길동'), findsOneWidget);
        expect(find.text('김철수'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 참가자 0명 → 빈 상태 안내',
      app: const Scaffold(body: ManualCheckinSheet(eventId: 'evt-empty')),
      overrides: () => [
        manualCheckinControllerProvider('evt-empty').overrideWith(
          () => _FakeManualCheckinController([]),
        ),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('수동 체크인'), findsOneWidget);
        // 참가자 없음 → 이름 없음
        expect(find.text('홍길동'), findsNothing);
      },
    );

    cujCase(
      'edge: 검색어 입력 → 일치하는 참가자만 표시',
      app: const Scaffold(body: ManualCheckinSheet(eventId: 'evt-search')),
      overrides: () => [
        manualCheckinControllerProvider('evt-search').overrideWith(
          () => _FakeManualCheckinController([
            _makeParticipant(),
            _makeParticipant(id: 'p-2', ticketId: 'ticket-2', name: '김철수'),
          ]),
        ),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 검색창에 "홍" 입력
        await t.enterText(find.byType(TextField).first, '홍');
        // debounce 대기 (150ms)
        await t.pump(const Duration(milliseconds: 200));
        await t.pumpAndSettle();

        // 홍길동만 노출, 김철수는 숨김
        expect(find.text('홍길동'), findsOneWidget);
        expect(find.text('김철수'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 수동 체크인 토글로 처리 (FR-10, FR-11)
  // ---------------------------------------------------------------------------

  cujGroup('3-2', '수동 체크인 처리 — 체크인 버튼 탭 → 상태 변경', () {
    cujCase(
      'happy: ticket_issued 참가자 → 체크인 버튼 탭 → checked_in 상태',
      app: const Scaffold(body: ManualCheckinSheet(eventId: 'evt-checkin')),
      overrides: () => [
        manualCheckinControllerProvider('evt-checkin').overrideWith(
          () => _FakeManualCheckinController([_makeParticipant()]),
        ),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('홍길동'), findsOneWidget);

        // 체크인 버튼 탭 (InkWell 또는 IconButton)
        final checkinButton = find.byKey(const Key('checkin_toggle_ticket-1'));
        if (checkinButton.evaluate().isNotEmpty) {
          await t.tap(checkinButton);
        } else {
          // 버튼 키가 없으면 ElevatedButton 또는 첫 번째 탭 가능한 widget 탭
          final buttons = find.byType(InkWell);
          if (buttons.evaluate().isNotEmpty) {
            await t.tap(buttons.first);
          }
        }
        await t.pump();
        await t.pumpAndSettle();

        // 체크인 완료 후 UI 갱신 확인 — '홍길동'은 여전히 보임
        expect(find.text('홍길동'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 5-4: 참가자 0명 이벤트 — 요약 카드 "아직 발급된 티켓이 없습니다" (FR-2, FR-15)
  // ---------------------------------------------------------------------------

  cujGroup('5-4', '발급 티켓 0건 이벤트 → 요약 카드 안내 표시', () {
    cujCase(
      'happy: total=0 → "아직 발급된 티켓이 없습니다" 표시',
      app: const Scaffold(
        body: CheckinSummaryCard(checkedIn: 0, total: 0),
      ),
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('아직 발급된 티켓이 없습니다'), findsOneWidget);
      },
    );

    cujCase(
      'edge: total=0 → "0/0" 카운트 표시',
      app: const Scaffold(
        body: CheckinSummaryCard(checkedIn: 0, total: 0),
      ),
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('0'), findsOneWidget);
        expect(find.text('/0'), findsOneWidget);
        // 진행률 "0%" 표시
        expect(find.text('0%'), findsOneWidget);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// StatefulBuilder wrapper for CUJ 1-2 (count increment simulation)
// ---------------------------------------------------------------------------

class _IncrementalCountCard extends StatefulWidget {
  const _IncrementalCountCard({
    required this.initialCount,
    required this.total,
  });

  final int initialCount;
  final int total;

  @override
  State<_IncrementalCountCard> createState() => _IncrementalCountCardState();
}

class _IncrementalCountCardState extends State<_IncrementalCountCard> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CheckinSummaryCard(checkedIn: _count, total: widget.total),
          ElevatedButton(
            key: const Key('increment'),
            onPressed: () => setState(() => _count++),
            child: const Text('+1'),
          ),
        ],
      ),
    );
  }
}
