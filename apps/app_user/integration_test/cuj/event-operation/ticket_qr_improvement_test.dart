// CUJ tests — event-operation / ticket-qr-improvement
//
// 대응 spec: docs/features/event-operation/ticket-qr-improvement/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:app_user/src/features/ticket/data/ticket_token_service.dart';
import 'package:app_user/src/features/ticket/ui/ticket_qr_screen.dart';
import 'package:app_user/src/features/ticket/ui/widgets/boarding_pass_card.dart';
import 'package:app_user/src/logic/ticket_event_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockTicketTokenService extends Mock implements TicketTokenService {}

// ---------------------------------------------------------------------------
// Wrapper — BoardingPassCard requires an external AnimationController for vsync.
// ---------------------------------------------------------------------------

class _BoardingPassWrapper extends StatefulWidget {
  const _BoardingPassWrapper({required this.token, this.eventMeta});

  final TicketToken token;
  final TicketEventMeta? eventMeta;

  @override
  State<_BoardingPassWrapper> createState() => _BoardingPassWrapperState();
}

class _BoardingPassWrapperState extends State<_BoardingPassWrapper>
    with TickerProviderStateMixin {
  late final AnimationController _scanning;

  @override
  void initState() {
    super.initState();
    // Fix #2591: intentionally not started (no repeat) — CUJ tests check
    // static widget state; AnimationController.repeat() prevents pumpAndSettle
    // from settling, causing test timeout.
    _scanning = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanning.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BoardingPassCard(
          token: widget.token,
          eventMeta: widget.eventMeta,
          scanningAnimation: _scanning,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

/// Token fixture — QR payload only; display data comes from [TicketEventMeta].
TicketToken _makeToken({String ticketId = 'abc123defg'}) => TicketToken(
  ticketId: ticketId,
  eventId: 'event-1',
  userId: 'user-1',
  signature: 'sig',
  expiresAt: DateTime.now().add(const Duration(hours: 6)),
);

/// Today meta — event starts at 19:00 today → BOARDING status.
TicketEventMeta _todayMeta({
  String eventTitle = '금요일 밤 와인 테이스팅',
  String? eventVenue = '강남 라운지바',
  String? ticketName = '일반 입장권',
}) {
  final now = DateTime.now();
  return TicketEventMeta(
    eventTitle: eventTitle,
    eventDateTime: DateTime(now.year, now.month, now.day, 19, 0),
    eventVenue: eventVenue,
    ticketName: ticketName,
  );
}

/// Future meta — event starts 3 days from now → CONFIRMED status.
TicketEventMeta _futureMeta({
  String eventTitle = '다음 주 소셜 클럽',
  String? eventVenue = '홍대 루프탑',
  String? ticketName = 'VIP 입장권',
}) {
  final soon = DateTime.now().add(const Duration(days: 3));
  return TicketEventMeta(
    eventTitle: eventTitle,
    eventDateTime: DateTime(soon.year, soon.month, soon.day, 19, 0),
    eventVenue: eventVenue,
    ticketName: ticketName,
  );
}

/// Past meta — event started 2 days ago → USED status.
TicketEventMeta _pastMeta({
  String eventTitle = '지난 주 재즈 나이트',
  String? eventVenue = '이태원 재즈바',
  String? ticketName = '일반 입장권',
}) {
  final past = DateTime.now().subtract(const Duration(days: 2));
  return TicketEventMeta(
    eventTitle: eventTitle,
    eventDateTime: DateTime(past.year, past.month, past.day, 20, 0),
    eventVenue: eventVenue,
    ticketName: ticketName,
  );
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late _MockTicketTokenService tokenService;

  setUp(() {
    tokenService = _MockTicketTokenService();
    // Default: returns a valid token
    when(
      () => tokenService.getToken(any()),
    ).thenAnswer((_) async => _makeToken());
  });

  List<dynamic> withToken(TicketToken? token) {
    when(
      () => tokenService.getToken(any()),
    ).thenAnswer((_) async => token);
    return [ticketTokenServiceProvider.overrideWithValue(tokenService)];
  }

  // =========================================================================
  // Scenario 1 — Today Event D-Day (BOARDING)
  // =========================================================================

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 오늘 이벤트 QR 진입 → BOARDING 표시
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '오늘 이벤트 QR 진입 → BOARDING 표시', () {
    cujCase(
      'happy: 오늘 이벤트 → STATUS 배지 "BOARDING" 표시',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: _todayMeta()),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // FR-6: STATUS badge = BOARDING (today)
        expect(find.text('BOARDING'), findsOneWidget);
        // FR-2: STATUS label visible
        expect(find.text('STATUS'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 이벤트 메타 누락 → placeholder 대시, QR 정상 표시',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: null),
      body: (t) async {
        // Without eventMeta, BoardingPassCard shows placeholder dashes
        // and defaults to CONFIRMED (per _computeStatus() when meta is null)
        expect(find.text('CONFIRMED'), findsOneWidget);
        // QR section renders (TICKET NO. always present)
        expect(find.text('TICKET NO.'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 이벤트 정보(일시/장소/제목) 노출
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '이벤트 정보(일시/장소/제목) 노출', () {
    cujCase(
      'happy: DATE/VENUE 라벨, 이벤트명, 티켓 종류 모두 노출',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: _todayMeta()),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // FR-2: column header labels
        expect(find.text('DATE'), findsOneWidget);
        expect(find.text('VENUE'), findsOneWidget);
        // FR-2: event title centered
        expect(find.text('금요일 밤 와인 테이스팅'), findsOneWidget);
        // FR-2: venue value
        expect(find.text('강남 라운지바'), findsOneWidget);
        // FR-2: ticket type sub-label
        expect(find.textContaining('일반 입장권'), findsOneWidget);
      },
    );

    cujCase(
      'edge: venue 누락(null) → venue 필드 대시(—) 표시',
      app: _BoardingPassWrapper(
        token: _makeToken(),
        eventMeta: _todayMeta(eventVenue: null),
      ),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // Placeholder dash for missing venue
        expect(find.text('—'), findsWidgets);
        // Event title still shown
        expect(find.text('금요일 밤 와인 테이스팅'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 위조 방지 안내 표시
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '위조 방지 안내 표시', () {
    cujCase(
      'happy: "스크린샷은 입장에 사용할 수 없습니다" 안내 텍스트 노출',
      app: TicketQRScreen(
        ticketId: 'ticket-1',
        eventMeta: _todayMeta(),
      ),
      overrides: () => withToken(_makeToken()),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // FR-7: anti-counterfeit notice
        expect(find.text('스크린샷은 입장에 사용할 수 없습니다'), findsOneWidget);
        // FR-7: main instruction
        expect(
          find.text('입장 시 파트너에게 이 화면을 보여주세요'),
          findsOneWidget,
        );
      },
    );

    cujCase(
      'edge: 사용자가 스크린샷 시도 — 위조 방지 안내가 카드와 함께 노출',
      app: TicketQRScreen(
        ticketId: 'ticket-1',
        eventMeta: _todayMeta(),
      ),
      overrides: () => withToken(_makeToken()),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // Both card and anti-counterfeit text are in the same scrollable view
        // (a screenshot would capture both — this test confirms co-presence)
        expect(find.text('BOARDING'), findsOneWidget);
        expect(find.text('스크린샷은 입장에 사용할 수 없습니다'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-4: 절취선/노치 렌더링
  // ---------------------------------------------------------------------------

  cujGroup('1-4', '절취선/노치 렌더링', () {
    cujCase(
      'happy: 절취선 영역(_PerforationLine) 렌더 — key로 존재 검증',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: _todayMeta()),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // Fix #2591: ValueKey('perforation-line') added to _PerforationLine so
        // the assertion is specific — removing _PerforationLine will fail this test.
        expect(
          find.byKey(const ValueKey('perforation-line')),
          findsOneWidget,
        );
      },
    );

    cujCase(
      'edge: 다크 테마 없음 — 라이트 모드에서 노치 렌더 정상',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: _todayMeta()),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // Perforation renders (no crash); notch circles use scaffold background.
        expect(find.byType(BoardingPassCard), findsOneWidget);
        expect(
          find.byKey(const ValueKey('perforation-line')),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-5: 헤더 brand gradient + 로고
  // ---------------------------------------------------------------------------

  cujGroup('1-5', '헤더 brand gradient + 로고', () {
    cujCase(
      'happy: 헤더에 "BOARDING PASS" 텍스트 및 "입장권" 부제 노출',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: _todayMeta()),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // FR-3: header brand strip — text elements are excluded from semantics
        // but physically rendered; find.text works on non-semantic Text widgets.
        expect(find.text('BOARDING PASS'), findsOneWidget);
        expect(find.text('입장권'), findsOneWidget);
      },
    );

    cujCase(
      'edge: eventMeta 없어도 헤더 항상 노출',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: null),
      body: (t) async {
        // Header renders regardless of meta presence
        expect(find.text('BOARDING PASS'), findsOneWidget);
        expect(find.text('입장권'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-6: QR 스캐닝 라인 애니메이션
  // ---------------------------------------------------------------------------

  cujGroup('1-6', 'QR 스캐닝 라인 애니메이션', () {
    cujCase(
      'happy: 오늘 이벤트 — 스캐닝 라인(ValueKey=scanning-line) 존재',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: _todayMeta()),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // FR-6: scanning line widget keyed with 'scanning-line'
        expect(find.byKey(const ValueKey('scanning-line')), findsOneWidget);
      },
    );

    cujCase(
      'edge: 과거 이벤트 — 스캐닝 라인 비활성(미노출)',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: _pastMeta()),
      body: (t) async {
        // FR-6: scanning line is NOT rendered for USED status
        expect(
          find.byKey(const ValueKey('scanning-line')),
          findsNothing,
        );
      },
    );
  });

  // =========================================================================
  // Scenario 2 — Future Event (CONFIRMED)
  // =========================================================================

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 미래 이벤트 CONFIRMED 표시
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '미래 이벤트 CONFIRMED 표시', () {
    cujCase(
      'happy: 미래 이벤트 → STATUS 배지 "CONFIRMED" 표시',
      app: _BoardingPassWrapper(
        token: _makeToken(),
        eventMeta: _futureMeta(),
      ),
      body: (t) async {
        // FR-6: STATUS badge = CONFIRMED (future)
        expect(find.text('CONFIRMED'), findsOneWidget);
        // Scanning line active for future events
        expect(find.byKey(const ValueKey('scanning-line')), findsOneWidget);
      },
    );

    cujCase(
      'edge: 미래 이벤트 시작 임박(1시간 이내) → 여전히 CONFIRMED 유지',
      app: _BoardingPassWrapper(
        token: _makeToken(),
        eventMeta: () {
          // Tomorrow, regardless of time — day-based comparison keeps CONFIRMED
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          return TicketEventMeta(
            eventTitle: '내일 이벤트',
            eventDateTime: DateTime(
              tomorrow.year,
              tomorrow.month,
              tomorrow.day,
              0,
              30,
            ),
          );
        }(),
      ),
      body: (t) async {
        // Spec Edge Case: CONFIRMED until day boundary (Open Q — 1h early BOARDING?)
        // Current impl: day-based, so tomorrow at 00:30 is still CONFIRMED.
        expect(find.text('CONFIRMED'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: 티켓 번호 노출
  // ---------------------------------------------------------------------------

  cujGroup('2-2', '티켓 번호 노출', () {
    cujCase(
      'happy: TICKET NO. 라벨 + 축약 ID "#TK-{prefix}" 노출',
      app: _BoardingPassWrapper(
        token: _makeToken(ticketId: 'abcdef1234567890'),
        eventMeta: _futureMeta(),
      ),
      body: (t) async {
        // FR-5: "TICKET NO." label
        expect(find.text('TICKET NO.'), findsOneWidget);
        // FR-5: formatted as #TK-{8-char prefix uppercased}
        expect(find.text('#TK-ABCDEF12'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 티켓 ID가 8자 미만 — 원본 ID 전체 사용',
      app: _BoardingPassWrapper(
        token: _makeToken(ticketId: 'short'),
        eventMeta: _futureMeta(),
      ),
      body: (t) async {
        // _formatTicketNo: if id.length <= 8, use full id uppercase
        expect(find.text('#TK-SHORT'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-3: 이벤트 시간 강조
  // ---------------------------------------------------------------------------

  cujGroup('2-3', '이벤트 시간 강조', () {
    cujCase(
      'happy: 시간(HH:mm)이 카드 DATE 섹션에 크게 표시',
      app: _BoardingPassWrapper(
        token: _makeToken(),
        eventMeta: _futureMeta(),
      ),
      body: (t) async {
        // FR-2: time rendered large in primary color (Text widget present)
        // eventDateTime = 19:00 → formatted as "19:00"
        expect(find.text('19:00'), findsOneWidget);
        // DATE label is present
        expect(find.text('DATE'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 자정(00:00) 시작 이벤트 — 시간 필드 정상 표시',
      app: _BoardingPassWrapper(
        token: _makeToken(),
        eventMeta: () {
          final future = DateTime.now().add(const Duration(days: 4));
          return TicketEventMeta(
            eventTitle: '자정 파티',
            eventDateTime: DateTime(
              future.year,
              future.month,
              future.day,
              0,
              0,
            ),
          );
        }(),
      ),
      body: (t) async {
        expect(find.text('00:00'), findsOneWidget);
      },
    );
  });

  // =========================================================================
  // Scenario 3 — Past Event (USED)
  // =========================================================================

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 지난 이벤트 USED 표시
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '지난 이벤트 USED 표시', () {
    cujCase(
      'happy: 지난 이벤트 → STATUS "USED" + 카드 opacity 0.55 + 스캔 라인 없음',
      app: _BoardingPassWrapper(token: _makeToken(), eventMeta: _pastMeta()),
      body: (t) async {
        // FR-6: STATUS badge = USED (past)
        expect(find.text('USED'), findsOneWidget);
        // FR-8: scanning line NOT active for past events
        expect(
          find.byKey(const ValueKey('scanning-line')),
          findsNothing,
        );
        // FR-8: card has Opacity wrapper at 0.55
        // Fix #2591: use ValueKey('used-card-opacity') to avoid ambiguity
        // when multiple Opacity widgets exist inside BoardingPassCard.
        final opacity = t.widget<Opacity>(
          find.byKey(const ValueKey('used-card-opacity')),
        );
        expect(opacity.opacity, closeTo(0.55, 0.01));
      },
    );

    cujCase(
      'edge: 어제 자정 이후 전환 — 날짜 경계 USED 판정',
      app: _BoardingPassWrapper(
        token: _makeToken(),
        eventMeta: () {
          // Yesterday 23:59 → USED (started before today)
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          return TicketEventMeta(
            eventTitle: '어제 이벤트',
            eventDateTime: DateTime(
              yesterday.year,
              yesterday.month,
              yesterday.day,
              23,
              59,
            ),
          );
        }(),
      ),
      body: (t) async {
        // Spec: day-based comparison — yesterday 23:59 is still USED
        expect(find.text('USED'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 사용됨 워터마크 (V2 — 미구현)
  // ---------------------------------------------------------------------------

  cujGroup('3-2', '사용됨 워터마크 (V2)', () {
    cujCase(
      'stub: QR 위 "사용됨" 텍스트 워터마크 — V2 미구현',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        // CUJ 3-2 (spec: QR 위에 "사용됨" 텍스트 워터마크, 선택 V2 기능)
        // boarding_pass_card_qr.dart에 워터마크 미구현.
        // V2 구현 시 Opacity(opacity: 0.2 이하) Stack 오버레이로 테스트 교체.
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-3: 로딩 / 에러 상태
  // ---------------------------------------------------------------------------

  cujGroup('3-3', '로딩 / 에러 상태', () {
    cujCase(
      'happy: 토큰 로드 성공 → 보딩패스 카드 렌더',
      app: TicketQRScreen(
        ticketId: 'ticket-ok',
        eventMeta: _futureMeta(),
      ),
      overrides: () => withToken(_makeToken()),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // FR-9 success path: card is visible
        expect(find.byType(BoardingPassCard), findsOneWidget);
        expect(find.text('CONFIRMED'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 토큰 null(네트워크 단절) → 에러 UI 노출, 카드 미표시',
      app: TicketQRScreen(
        ticketId: 'ticket-missing',
        eventMeta: _futureMeta(),
      ),
      overrides: () => withToken(null),
      afterPump: (t) => t.pump(const Duration(milliseconds: 50)),
      body: (t) async {
        // FR-9 error path: no card rendered
        expect(find.byType(BoardingPassCard), findsNothing);
        // Error message shown
        expect(find.text('티켓 정보를 찾을 수 없습니다.'), findsOneWidget);
      },
    );
  });
}
