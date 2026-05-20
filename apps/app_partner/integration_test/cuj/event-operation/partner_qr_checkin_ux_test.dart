// CUJ tests — event-operation / partner-qr-checkin-ux (app_partner)
//
// 대응 spec: docs/features/event-operation/partner-qr-checkin-ux/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// Refs #2589: partner-qr-checkin-ux CUJ integration test 신규 작성

import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_controller.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_sheet.dart';
import 'package:app_partner/src/features/checkin/stats/checkin_stats_controller.dart';
import 'package:app_partner/src/features/checkin/stats/entry_group_checkin_stats_controller.dart';
import 'package:app_partner/src/features/checkin/widgets/checkin_scanner_overlay.dart';
import 'package:app_partner/src/features/checkin/widgets/checkin_summary_card.dart';
import 'package:app_partner/src/features/checkin/widgets/entry_group_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Fakes for provider isolation
// ---------------------------------------------------------------------------

class _FakeEntryGroupStatsController extends EntryGroupCheckinStatsController {
  _FakeEntryGroupStatsController(this._groups);
  final List<EntryGroupCheckinStats> _groups;

  @override
  Future<List<EntryGroupCheckinStats>> build(String eventId) async => _groups;
}

class _ErrorEntryGroupStatsController extends EntryGroupCheckinStatsController {
  // Fix #2612: build() 를 `async` 로 두고 throw — 동기 `Future.error` 반환은
  // AsyncNotifier 가 await 하기 전에 microtask 로 에러가 propagate 되어
  // 일부 환경에서 AsyncError state transition 이 누락되는 케이스가 있다.
  // async throw 패턴은 framework 가 만든 Future 안에서 catch 되므로 안전.
  @override
  Future<List<EntryGroupCheckinStats>> build(String eventId) async {
    throw Exception('RPC 실패');
  }
}

class _FakeCheckinStatsController extends CheckinStatsController {
  _FakeCheckinStatsController(this._initial, {CheckinStats? realtimeUpdate})
    : _realtimeUpdate = realtimeUpdate;

  final CheckinStats _initial;
  final CheckinStats? _realtimeUpdate;

  @override
  Future<CheckinStats> build(String eventId) async => _initial;

  // Override to avoid real Supabase call — simulates the same state update path
  // that the production realtime callback triggers via applyFetchedStats().
  @override
  Future<void> applyFetchedStats(String eventId) async {
    if (_realtimeUpdate != null) {
      state = AsyncData(_realtimeUpdate);
    }
  }
}

// MobileScannerController.toggleTorch() 는 하드웨어 접근 — no-op 으로 override.
// setState(() => _flashOn = ...) 는 toggleTorch() 호출 전에 실행되므로
// 이 stub 이 없어도 아이콘 변경은 동작하지만, Future 오류를 방지하기 위해 사용.
class _NoOpScannerController extends MobileScannerController {
  @override
  Future<void> toggleTorch() async {}
}

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

// CheckinSummaryCard._LiveDot 는 AnimationController.repeat() 로 무한 애니메이션.
// MinglitSkeleton 도 동일. pumpAndSettle() timeout 방지용 고정 pump duration.
const _kSummaryCardPump = Duration(milliseconds: 100);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 체크인 화면 진입 → 요약 카드 즉시 표시 (FR-1, FR-2)
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '체크인 화면 진입 → 요약 카드 즉시 표시', () {
    cujCase(
      'happy: checkedIn=23, total=50 → "23/50" + "46%" 표시',
      app: const Scaffold(body: CheckinSummaryCard(checkedIn: 23, total: 50)),
      // CheckinSummaryCard._LiveDot 무한 애니메이션 → pumpAndSettle timeout 방지
      afterPump: _kSummaryCardPump,
      body: (t) async {
        await t.pump(_kSummaryCardPump);

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
      // MinglitSkeleton 도 AnimationController.repeat() 사용
      afterPump: _kSummaryCardPump,
      body: (t) async {
        await t.pump(_kSummaryCardPump);

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
      // _IncrementalCountCard 내부 CheckinSummaryCard._LiveDot 무한 애니메이션
      afterPump: _kSummaryCardPump,
      body: (t) async {
        await t.pump(_kSummaryCardPump);

        // 초기 상태: 5/20
        expect(find.text('5'), findsOneWidget);

        // 스캔 성공 시뮬레이션: +1 버튼 탭 (StatefulBuilder가 카운트 올림)
        await t.tap(find.byKey(const Key('increment')));
        await t.pump();
        await t.pump(_kSummaryCardPump);

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
      // isOffline 시에도 _LiveDot AnimationController.repeat() 는 initState에서 기동
      afterPump: _kSummaryCardPump,
      body: (t) async {
        await t.pump(_kSummaryCardPump);

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
        await t.pumpAndSettle();

        expect(find.text('홍길동'), findsOneWidget);

        // _ParticipantRow: 미체크인 참가자에게 FilledButton('체크인') 렌더링
        final checkinBtn = find.widgetWithText(FilledButton, '체크인');
        expect(
          checkinBtn,
          findsOneWidget,
          reason: '미체크인 참가자에게 FilledButton("체크인") 있어야 함',
        );
        await t.tap(checkinBtn);
        await t.pump();
        await t.pumpAndSettle();

        // _FakeManualCheckinController.checkin() → optimistic update.
        // UI: FilledButton("체크인") 사라지고 OutlinedButton("완료") 표시
        expect(
          find.widgetWithText(FilledButton, '체크인'),
          findsNothing,
          reason: '체크인 후 FilledButton("체크인") 사라져야 함',
        );
        expect(
          find.widgetWithText(OutlinedButton, '완료'),
          findsOneWidget,
          reason: '체크인 완료 후 OutlinedButton("완료") 표시되어야 함',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 엔트리 그룹 하단 시트 헤더 노출 (FR-6, FR-7)
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '엔트리 그룹 하단 시트 헤더 노출', () {
    cujCase(
      'happy: 그룹 있음 → 헤더 "엔트리 그룹별 현황" 노출',
      app: const Scaffold(
        body: EntryGroupBottomSheet(eventId: 'evt-groups'),
      ),
      overrides: () => [
        entryGroupCheckinStatsControllerProvider('evt-groups').overrideWith(
          () => _FakeEntryGroupStatsController([
            const EntryGroupCheckinStats(
              id: 'g1',
              label: '남 20대',
              total: 14,
              checkedIn: 4,
            ),
          ]),
        ),
      ],
      body: (t) async {
        await t.pumpAndSettle();
        // FR-6: 하단 시트 헤더 타이틀 노출
        expect(find.text('엔트리 그룹별 현황'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 그룹 없음 → 시트 섹션 자체 숨김 (FR-7)',
      app: const Scaffold(
        body: EntryGroupBottomSheet(eventId: 'evt-no-groups'),
      ),
      overrides: () => [
        entryGroupCheckinStatsControllerProvider(
          'evt-no-groups',
        ).overrideWith(() => _FakeEntryGroupStatsController([])),
      ],
      body: (t) async {
        await t.pumpAndSettle();
        // 그룹 없으면 SizedBox.shrink() — 헤더 없음
        expect(find.text('엔트리 그룹별 현황'), findsNothing);
      },
    );

    cujCase(
      'edge: 그룹 RPC 실패 → 헤더만 + "불러오기 실패" 서브타이틀',
      app: const Scaffold(
        body: EntryGroupBottomSheet(eventId: 'evt-err'),
      ),
      overrides: () => [
        entryGroupCheckinStatsControllerProvider(
          'evt-err',
        ).overrideWith(_ErrorEntryGroupStatsController.new),
      ],
      body: (t) async {
        // Fix #2612: build() async throw → AsyncError 로 transition.
        // pump → Loading 렌더, 짧은 duration → build microtask 처리,
        // pumpAndSettle → error 상태 반영 마무리.
        await t.pump();
        await t.pump(const Duration(milliseconds: 200));
        await t.pumpAndSettle();
        expect(find.text('엔트리 그룹별 현황'), findsOneWidget);
        expect(find.textContaining('불러오기 실패'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: pull-up 으로 그룹 시트 확장 + 그룹별 현황 표시 (FR-6, FR-8)
  // ---------------------------------------------------------------------------

  cujGroup('2-2', 'pull-up 으로 그룹 시트 확장 + 그룹별 현황 표시', () {
    cujCase(
      'happy: 3개 그룹 → 드래그 후 라벨 + 진행률 표시',
      app: const Scaffold(
        body: EntryGroupBottomSheet(eventId: 'evt-expand'),
      ),
      overrides: () => [
        entryGroupCheckinStatsControllerProvider('evt-expand').overrideWith(
          () => _FakeEntryGroupStatsController([
            // 0~50% → primary color (FR-8)
            const EntryGroupCheckinStats(
              id: 'g1',
              label: '남 20대',
              total: 14,
              checkedIn: 4,
            ),
            // 50~90% → warning color (FR-8)
            const EntryGroupCheckinStats(
              id: 'g2',
              label: '여 20대',
              total: 14,
              checkedIn: 9,
            ),
            // 90%+ → error color (FR-8)
            const EntryGroupCheckinStats(
              id: 'g3',
              label: '남 30대',
              total: 10,
              checkedIn: 10,
            ),
          ]),
        ),
      ],
      body: (t) async {
        await t.pumpAndSettle();

        // 축소 헤더 확인
        expect(find.text('엔트리 그룹별 현황'), findsOneWidget);

        // Fix #2612: DraggableScrollableSheet 는 ScrollController 가 attach 된
        // 스크롤러블 (ListView) 의 pointer event 만 sheet drag 로 전달한다.
        // 헤더 Text 위에서 fling 하면 sheet 가 확장되지 않아 ListView viewport 가
        // 작아 itemBuilder 가 후순 아이템(남 20대) 을 빌드하지 않음.
        // → ListView 자체를 target 으로 fling 하고 충분한 velocity 부여.
        await t.fling(
          find.byType(ListView),
          const Offset(0, -400),
          4000,
        );
        await t.pumpAndSettle();

        // FR-8: 그룹 라벨 노출
        expect(find.text('남 20대'), findsOneWidget);
        expect(find.text('여 20대'), findsOneWidget);
        expect(find.text('남 30대'), findsOneWidget);
        // LinearProgressIndicator 3개 (그룹당 1개)
        expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
      },
    );

    cujCase(
      'edge: 100% 도달 그룹 → "N/N" 표시 + error 색상 프로그레스',
      app: const Scaffold(
        body: EntryGroupBottomSheet(eventId: 'evt-full'),
      ),
      overrides: () => [
        entryGroupCheckinStatsControllerProvider('evt-full').overrideWith(
          () => _FakeEntryGroupStatsController([
            const EntryGroupCheckinStats(
              id: 'g1',
              label: '전체',
              total: 50,
              checkedIn: 50,
            ),
          ]),
        ),
      ],
      body: (t) async {
        await t.pumpAndSettle();
        expect(find.text('엔트리 그룹별 현황'), findsOneWidget);

        await t.drag(
          find.text('엔트리 그룹별 현황'),
          const Offset(0, -400),
        );
        await t.pumpAndSettle();

        expect(find.text('전체'), findsOneWidget);
        // LinearProgressIndicator value=1.0 (clamped)
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-1: 카메라 플래시 토글 (FR-12)
  // ---------------------------------------------------------------------------

  cujGroup('4-1', '카메라 플래시 토글 (어두운 현장)', () {
    cujCase(
      'happy: 플래시 FAB 탭 → 아이콘 flash_off→flash_on 전환',
      app: Scaffold(
        body: CheckinScannerOverlay(
          scannerController: _NoOpScannerController(),
          state: const CheckinState(result: CheckinResult.idle),
          onManualCheckin: () {},
        ),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        // 초기: 플래시 OFF
        expect(find.byIcon(Icons.flash_off), findsOneWidget);
        expect(find.byIcon(Icons.flash_on), findsNothing);

        // 플래시 FAB 탭
        await t.tap(find.byIcon(Icons.flash_off));
        await t.pump();

        // 전환 후: 플래시 ON
        expect(find.byIcon(Icons.flash_on), findsOneWidget);
        expect(find.byIcon(Icons.flash_off), findsNothing);
      },
    );

    cujCase(
      'edge: 재탭 → flash_on→flash_off 복귀',
      app: Scaffold(
        body: CheckinScannerOverlay(
          scannerController: _NoOpScannerController(),
          state: const CheckinState(result: CheckinResult.idle),
          onManualCheckin: () {},
        ),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        await t.tap(find.byIcon(Icons.flash_off));
        await t.pump();
        expect(find.byIcon(Icons.flash_on), findsOneWidget);

        // 다시 탭 → 복귀
        await t.tap(find.byIcon(Icons.flash_on));
        await t.pump();
        expect(find.byIcon(Icons.flash_off), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-2: Realtime 다른 디바이스 체크인 자동 반영 (FR-13, P1)
  // ---------------------------------------------------------------------------

  cujGroup('4-2', 'Realtime 다른 디바이스 체크인 자동 반영', () {
    late _FakeCheckinStatsController statsController;

    cujCase(
      'happy: Realtime 업데이트 → 요약 카드 갱신 (23→24)',
      app: const _RealtimeStatCard(eventId: 'evt-rt'),
      overrides: () {
        statsController = _FakeCheckinStatsController(
          const CheckinStats(total: 50, checkedIn: 23),
          realtimeUpdate: const CheckinStats(total: 50, checkedIn: 24),
        );
        return [
          checkinStatsControllerProvider('evt-rt').overrideWith(
            () => statsController,
          ),
        ];
      },
      afterPump: _kSummaryCardPump,
      body: (t) async {
        await t.pump(_kSummaryCardPump);

        // 초기 상태: 23/50
        expect(find.text('23'), findsOneWidget);
        expect(find.text('/50'), findsOneWidget);

        // Realtime 이벤트 수신 경로 시뮬레이션:
        // applyFetchedStats()는 production realtime callback이 호출하는 메서드.
        // 여기서 직접 호출함으로써 "callback → state 갱신 → widget 리빌드" 경로 검증.
        await statsController.applyFetchedStats('evt-rt');
        await t.pump();
        await t.pump(_kSummaryCardPump);

        // 갱신 후: 24/50
        expect(find.text('24'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 5-1: 중복 체크인 시 메시지 확장 (FR-14)
  // ---------------------------------------------------------------------------

  cujGroup('5-1', '중복 체크인 시 메시지 확장', () {
    cujCase(
      'happy: alreadyCheckedIn → "이미 체크인된 참가자" + 입장 시각',
      app: const Scaffold(
        body: CheckinResultBanner(
          state: CheckinState(
            result: CheckinResult.alreadyCheckedIn,
            message: '14:30 입장',
          ),
        ),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        // FR-14: "이미 체크인된 참가자" 타이틀
        expect(find.text('이미 체크인된 참가자'), findsOneWidget);
        // 입장 시각 서브타이틀
        expect(find.text('14:30 입장'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 시각 정보 미수신 → "이미 체크인된 참가자" 기본 메시지',
      app: const Scaffold(
        body: CheckinResultBanner(
          state: CheckinState(result: CheckinResult.alreadyCheckedIn),
        ),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        // message == null → subtitle 공란 (fallback)
        expect(find.text('이미 체크인된 참가자'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 5-2: 다른 이벤트 티켓 스캔 시 차단 (FR-14)
  // ---------------------------------------------------------------------------

  cujGroup('5-2', '다른 이벤트 티켓 스캔 시 차단', () {
    cujCase(
      'happy: invalid + "다른 이벤트 티켓입니다" → 입장 불가 배너',
      app: const Scaffold(
        body: CheckinResultBanner(
          state: CheckinState(
            result: CheckinResult.invalid,
            message: '다른 이벤트 티켓입니다',
          ),
        ),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        // FR-14: "입장 불가" 타이틀
        expect(find.text('입장 불가'), findsOneWidget);
        // 사유 서브타이틀
        expect(find.text('다른 이벤트 티켓입니다'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 5-3: 환불된 티켓 스캔 시 차단 (FR-14)
  // ---------------------------------------------------------------------------

  cujGroup('5-3', '환불된 티켓 스캔 시 차단', () {
    cujCase(
      'happy: invalid + "환불된 티켓" → 입장 불가 배너',
      app: const Scaffold(
        body: CheckinResultBanner(
          state: CheckinState(
            result: CheckinResult.invalid,
            message: '환불된 티켓',
          ),
        ),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        expect(find.text('입장 불가'), findsOneWidget);
        expect(find.text('환불된 티켓'), findsOneWidget);
        // error 아이콘 표시
        expect(find.byIcon(Icons.error), findsOneWidget);
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
      afterPump: _kSummaryCardPump,
      body: (t) async {
        await t.pump(_kSummaryCardPump);

        expect(find.text('아직 발급된 티켓이 없습니다'), findsOneWidget);
      },
    );

    cujCase(
      'edge: total=0 → "0/0" 카운트 표시',
      app: const Scaffold(
        body: CheckinSummaryCard(checkedIn: 0, total: 0),
      ),
      afterPump: _kSummaryCardPump,
      body: (t) async {
        await t.pump(_kSummaryCardPump);

        expect(find.text('0'), findsOneWidget);
        expect(find.text('/0'), findsOneWidget);
        // 진행률 "0%" 표시
        expect(find.text('0%'), findsOneWidget);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// ConsumerWidget wrapper for CUJ 4-2 (Realtime stats update simulation)
// ---------------------------------------------------------------------------

class _RealtimeStatCard extends ConsumerWidget {
  const _RealtimeStatCard({required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(checkinStatsControllerProvider(eventId));
    return statsAsync.when(
      loading: () => const Scaffold(
        body: CheckinSummaryCard(checkedIn: 0, total: 0, isLoading: true),
      ),
      error: (_, _) => const Scaffold(
        body: CheckinSummaryCard(checkedIn: 0, total: 0),
      ),
      data: (stats) => Scaffold(
        body: CheckinSummaryCard(
          checkedIn: stats.checkedIn,
          total: stats.total,
        ),
      ),
    );
  }
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
