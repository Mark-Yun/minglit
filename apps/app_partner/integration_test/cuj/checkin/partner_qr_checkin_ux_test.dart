// CUJ tests — checkin / partner-qr-checkin-ux
//
// Issue: #2589 (CUJ coverage gap)
//
// 커버 범위:
//   CUJ 1-1 ~ 1-4: 스캔 결과 배너 (CheckinResultBanner)
//   CUJ 2-1 ~ 2-3: 체크인 탭 진입 (CheckinPlaceholderPage)
//   CUJ 3-1 ~ 3-6: 수동 체크인 (ManualCheckinSheet)
//
// 설계 결정:
//   - CheckinResultBanner: provider 의존 없는 순수 위젯 — 직접 렌더링.
//   - CheckinPlaceholderPage: currentPartnerInfoProvider + todayEventsProvider override.
//     QRScannerScreen(MobileScanner 카메라 하드웨어 필요)는 직접 테스트 제외.
//   - ManualCheckinSheet: _FakeManualCheckinController로 supabase 격리.
//     optimistic update는 fake notifier에서 동일하게 재현.
//     검색 debounce 150ms → pump(200ms)으로 통과.

import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:app_partner/src/features/checkin/checkin_placeholder_page.dart';
import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_controller.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_sheet.dart';
import 'package:app_partner/src/features/checkin/widgets/checkin_scanner_overlay.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Fake controller — supabase 없이 ManualCheckinSheet 격리
// ---------------------------------------------------------------------------

class _FakeManualCheckinController extends ManualCheckinController {
  _FakeManualCheckinController({
    required this.participants,
    this.checkinResult = 'success',
    this.shouldThrow = false,
  });

  final List<CheckinParticipant> participants;
  final String checkinResult;
  final bool shouldThrow;

  @override
  Future<List<CheckinParticipant>> build(String eventId) async => participants;

  @override
  Future<String> checkin(String ticketId) async {
    if (shouldThrow) throw Exception('network error');
    // Fix #2589: ManualCheckinController 와 동일한 optimistic update 재현
    state = state.whenData(
      (list) => list.map((p) {
        if (p.ticketId != ticketId) return p;
        return p.copyWith(status: 'checked_in', checkedInAt: DateTime.now());
      }).toList(),
    );
    return checkinResult;
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 5, 20, 19, 0);
final _fakePartner = const Partner(id: 'partner-1', name: '테스트파트너');

Event _makeEvent({
  String id = 'event-1',
  String title = '테스트 이벤트',
  int currentParticipants = 5,
  int maxParticipants = 20,
}) => Event(
      id: id,
      partyId: 'party-1',
      title: title,
      startTime: _now.subtract(const Duration(minutes: 30)),
      endTime: _now.add(const Duration(hours: 2)),
      createdAt: _now,
      updatedAt: _now,
      currentParticipants: currentParticipants,
      maxParticipants: maxParticipants,
      status: 'ongoing',
      tickets: const [],
      entryGroups: const [],
    );

CheckinParticipant _makeParticipant({
  String id = 'p1',
  String ticketId = 't1',
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

final _mixedParticipants = [
  _makeParticipant(id: 'p1', ticketId: 't1', name: '홍길동', phoneLast4: '1234'),
  _makeParticipant(id: 'p2', ticketId: 't2', name: '김철수', phoneLast4: '5678'),
  _makeParticipant(
    id: 'p3',
    ticketId: 't3',
    name: '이영희',
    phoneLast4: '9999',
    status: 'checked_in',
  ),
];

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================================================
  // CUJ 1: 스캔 결과 배너 (CheckinResultBanner)
  // ==========================================================================

  cujGroup('1-1', 'QR 스캔 성공 → 체크인 완료 배너', () {
    cujCase(
      'happy: success + userName → 체크 아이콘 + "체크인 완료" + 이름',
      app: Scaffold(
        body: CheckinResultBanner(
          state: const CheckinState(
            result: CheckinResult.success,
            userName: '홍길동',
          ),
        ),
      ),
      body: (t) async {
        expect(find.text('체크인 완료'), findsOneWidget);
        expect(find.text('홍길동'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );

    cujCase(
      'edge: userName null → subtitle 미렌더링',
      app: Scaffold(
        body: CheckinResultBanner(
          state: const CheckinState(result: CheckinResult.success),
        ),
      ),
      body: (t) async {
        expect(find.text('체크인 완료'), findsOneWidget);
        // empty subtitle → if(subtitle.isNotEmpty) 분기로 Text 미생성
        expect(
          find.descendant(
            of: find.byType(CheckinResultBanner),
            matching: find.byWidgetPredicate((w) => w is Text && w.data == ''),
          ),
          findsNothing,
        );
      },
    );
  });

  cujGroup('1-2', '이미 체크인된 참가자 스캔 → 경고 배너', () {
    cujCase(
      'happy: alreadyCheckedIn → info 아이콘 + "이미 체크인된 참가자" + 메시지',
      app: Scaffold(
        body: CheckinResultBanner(
          state: const CheckinState(
            result: CheckinResult.alreadyCheckedIn,
            message: '이미 입장한 참가자입니다.',
          ),
        ),
      ),
      body: (t) async {
        expect(find.text('이미 체크인된 참가자'), findsOneWidget);
        expect(find.text('이미 입장한 참가자입니다.'), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);
      },
    );
  });

  cujGroup('1-3', '유효하지 않은 QR → 입장 불가 배너', () {
    cujCase(
      'happy: invalid + message → 에러 아이콘 + "입장 불가" + 메시지',
      app: Scaffold(
        body: CheckinResultBanner(
          state: const CheckinState(
            result: CheckinResult.invalid,
            message: '유효하지 않은 티켓입니다.',
          ),
        ),
      ),
      body: (t) async {
        expect(find.text('입장 불가'), findsOneWidget);
        expect(find.text('유효하지 않은 티켓입니다.'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      },
    );

    cujCase(
      'edge: message null → 기본 메시지 "유효하지 않은 QR 코드입니다"',
      app: Scaffold(
        body: CheckinResultBanner(
          state: const CheckinState(result: CheckinResult.invalid),
        ),
      ),
      body: (t) async {
        expect(find.text('입장 불가'), findsOneWidget);
        expect(find.text('유효하지 않은 QR 코드입니다'), findsOneWidget);
      },
    );
  });

  cujGroup('1-4', '서버 에러 → 입장 불가 배너', () {
    cujCase(
      'happy: error 상태 → 에러 아이콘 + "입장 불가"',
      app: Scaffold(
        body: CheckinResultBanner(
          state: const CheckinState(result: CheckinResult.error),
        ),
      ),
      body: (t) async {
        expect(find.text('입장 불가'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      },
    );
  });

  // ==========================================================================
  // CUJ 2: 체크인 탭 진입 (CheckinPlaceholderPage)
  // ==========================================================================

  cujGroup('2-1', '오늘 이벤트 0개 → 빈 상태 화면', () {
    cujCase(
      'happy: 이벤트 없음 → 안내 텍스트 + QR 아이콘',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith((_) async => _fakePartner),
        todayEventsProvider('partner-1').overrideWith((_) async => []),
      ],
      body: (t) async {
        expect(find.text('오늘 예정된 이벤트가 없습니다'), findsOneWidget);
        expect(find.text('이벤트 당일에 체크인을 시작할 수 있어요'), findsOneWidget);
        expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      },
    );
  });

  cujGroup('2-2', '오늘 이벤트 2개 이상 → 이벤트 선택 페이지', () {
    cujCase(
      'happy: 이벤트 2개 → 선택 리스트 + 개수 안내',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith((_) async => _fakePartner),
        todayEventsProvider('partner-1').overrideWith(
          (_) async => [
            _makeEvent(id: 'event-1', title: '1번 이벤트'),
            _makeEvent(id: 'event-2', title: '2번 이벤트'),
          ],
        ),
      ],
      body: (t) async {
        expect(find.text('이벤트를 선택하세요'), findsOneWidget);
        expect(find.text('오늘 2개 이벤트가 진행됩니다'), findsOneWidget);
        expect(find.text('1번 이벤트'), findsOneWidget);
        expect(find.text('2번 이벤트'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 진행 중 이벤트 (startTime < now < endTime) → LIVE 배지',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith((_) async => _fakePartner),
        todayEventsProvider('partner-1').overrideWith(
          (_) async => [
            Event(
              id: 'event-live',
              partyId: 'party-1',
              title: '라이브 이벤트',
              startTime: DateTime.now().subtract(const Duration(minutes: 10)),
              endTime: DateTime.now().add(const Duration(hours: 1)),
              createdAt: _now,
              updatedAt: _now,
              currentParticipants: 3,
              maxParticipants: 10,
              status: 'ongoing',
              tickets: const [],
              entryGroups: const [],
            ),
            _makeEvent(id: 'event-2', title: '대기 이벤트'),
          ],
        ),
      ],
      body: (t) async {
        expect(find.text('LIVE'), findsOneWidget);
        expect(find.text('라이브 이벤트'), findsOneWidget);
        expect(find.text('대기 이벤트'), findsOneWidget);
      },
    );
  });

  cujGroup('2-3', '파트너 정보 없음 → 오류 메시지', () {
    cujCase(
      'happy: partner=null → "파트너 정보를 불러올 수 없습니다"',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith((_) async => null),
      ],
      body: (t) async {
        expect(find.text('파트너 정보를 불러올 수 없습니다'), findsOneWidget);
      },
    );
  });

  // ==========================================================================
  // CUJ 3: 수동 체크인 (ManualCheckinSheet)
  // ==========================================================================

  cujGroup('3-1', '이름으로 검색 → 참가자 필터링', () {
    cujCase(
      'happy: "홍" 입력 → 홍길동만 표시',
      app: Scaffold(body: ManualCheckinSheet(eventId: 'event-1')),
      overrides: () => [
        manualCheckinControllerProvider('event-1').overrideWith(
          () => _FakeManualCheckinController(participants: _mixedParticipants),
        ),
      ],
      body: (t) async {
        // 초기: 미체크인 2명, 체크인 완료 1명
        expect(find.text('미체크인 (2명)'), findsOneWidget);
        expect(find.text('체크인 완료 (1명)'), findsOneWidget);

        await t.enterText(
          find.widgetWithText(TextField, '이름 또는 전화 뒷자리 4자리'),
          '홍',
        );
        // debounce 150ms 통과
        await t.pump(const Duration(milliseconds: 200));
        await t.pumpAndSettle();

        expect(find.text('홍길동'), findsOneWidget);
        expect(find.text('김철수'), findsNothing);
        expect(find.text('이영희'), findsNothing);
        expect(find.text('미체크인 (1명)'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 빈 쿼리 → 전체 참가자 표시',
      app: Scaffold(body: ManualCheckinSheet(eventId: 'event-1')),
      overrides: () => [
        manualCheckinControllerProvider('event-1').overrideWith(
          () => _FakeManualCheckinController(participants: _mixedParticipants),
        ),
      ],
      body: (t) async {
        // 검색어 없으면 전체 목록 그대로
        expect(find.text('홍길동'), findsOneWidget);
        expect(find.text('김철수'), findsOneWidget);
        expect(find.text('이영희'), findsOneWidget);
      },
    );
  });

  cujGroup('3-2', '전화 뒷자리 4자리로 검색 → 참가자 필터링', () {
    cujCase(
      'happy: "5678" 입력 → 김철수만 표시',
      app: Scaffold(body: ManualCheckinSheet(eventId: 'event-1')),
      overrides: () => [
        manualCheckinControllerProvider('event-1').overrideWith(
          () => _FakeManualCheckinController(participants: _mixedParticipants),
        ),
      ],
      body: (t) async {
        await t.enterText(
          find.widgetWithText(TextField, '이름 또는 전화 뒷자리 4자리'),
          '5678',
        );
        await t.pump(const Duration(milliseconds: 200));
        await t.pumpAndSettle();

        expect(find.text('김철수'), findsOneWidget);
        expect(find.text('홍길동'), findsNothing);
        expect(find.text('미체크인 (1명)'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 4자리 미만 숫자 "123" → 이름 검색으로 처리 (결과 없음)',
      app: Scaffold(body: ManualCheckinSheet(eventId: 'event-1')),
      overrides: () => [
        manualCheckinControllerProvider('event-1').overrideWith(
          () => _FakeManualCheckinController(participants: _mixedParticipants),
        ),
      ],
      body: (t) async {
        await t.enterText(
          find.widgetWithText(TextField, '이름 또는 전화 뒷자리 4자리'),
          '123',
        );
        await t.pump(const Duration(milliseconds: 200));
        await t.pumpAndSettle();

        // 숫자 3자리 → 전화 매칭 아님 → 이름 검색 → 이름에 "123" 없음
        expect(find.text('검색 결과가 없습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('3-3', '체크인 버튼 탭 → optimistic 완료 표시', () {
    cujCase(
      'happy: "체크인" 탭 → "완료" OutlinedButton 으로 전환',
      app: Scaffold(body: ManualCheckinSheet(eventId: 'event-1')),
      overrides: () => [
        manualCheckinControllerProvider('event-1').overrideWith(
          () => _FakeManualCheckinController(
            participants: [
              _makeParticipant(id: 'p1', ticketId: 't1', name: '홍길동'),
            ],
          ),
        ),
      ],
      body: (t) async {
        expect(find.widgetWithText(FilledButton, '체크인'), findsOneWidget);

        await t.tap(find.widgetWithText(FilledButton, '체크인'));
        await t.pumpAndSettle();

        // optimistic update → checked_in → "완료" 버튼 (disabled OutlinedButton)
        expect(find.widgetWithText(OutlinedButton, '완료'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, '체크인'), findsNothing);
      },
    );
  });

  cujGroup('3-4', '이미 체크인된 참가자 수동 체크인 → 스낵바', () {
    cujCase(
      'happy: already_checked_in → "홍길동님은 이미 체크인되었습니다" 스낵바',
      app: Scaffold(body: ManualCheckinSheet(eventId: 'event-1')),
      overrides: () => [
        manualCheckinControllerProvider('event-1').overrideWith(
          () => _FakeManualCheckinController(
            participants: [
              _makeParticipant(id: 'p1', ticketId: 't1', name: '홍길동'),
            ],
            checkinResult: 'already_checked_in',
          ),
        ),
      ],
      body: (t) async {
        await t.tap(find.widgetWithText(FilledButton, '체크인'));
        await t.pumpAndSettle();

        expect(find.text('홍길동님은 이미 체크인되었습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('3-5', '수동 체크인 오류 → 오류 스낵바', () {
    cujCase(
      'happy: 네트워크 예외 → "체크인 처리 중 오류가 발생했습니다" 스낵바',
      app: Scaffold(body: ManualCheckinSheet(eventId: 'event-1')),
      overrides: () => [
        manualCheckinControllerProvider('event-1').overrideWith(
          () => _FakeManualCheckinController(
            participants: [
              _makeParticipant(id: 'p1', ticketId: 't1', name: '홍길동'),
            ],
            shouldThrow: true,
          ),
        ),
      ],
      body: (t) async {
        await t.tap(find.widgetWithText(FilledButton, '체크인'));
        await t.pumpAndSettle();

        expect(find.text('체크인 처리 중 오류가 발생했습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('3-6', '검색 결과 없음 / 참가자 없음', () {
    cujCase(
      'happy: 없는 이름 검색 → "검색 결과가 없습니다"',
      app: Scaffold(body: ManualCheckinSheet(eventId: 'event-1')),
      overrides: () => [
        manualCheckinControllerProvider('event-1').overrideWith(
          () => _FakeManualCheckinController(participants: _mixedParticipants),
        ),
      ],
      body: (t) async {
        await t.enterText(
          find.widgetWithText(TextField, '이름 또는 전화 뒷자리 4자리'),
          '존재하지않는이름',
        );
        await t.pump(const Duration(milliseconds: 200));
        await t.pumpAndSettle();

        expect(find.text('검색 결과가 없습니다'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 참가자 0명 이벤트 → "참가자가 없습니다"',
      app: Scaffold(body: ManualCheckinSheet(eventId: 'event-1')),
      overrides: () => [
        manualCheckinControllerProvider('event-1').overrideWith(
          () => _FakeManualCheckinController(participants: const []),
        ),
      ],
      body: (t) async {
        expect(find.text('참가자가 없습니다'), findsOneWidget);
      },
    );
  });
}
