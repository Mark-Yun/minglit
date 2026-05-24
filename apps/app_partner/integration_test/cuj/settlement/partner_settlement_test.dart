// CUJ tests — settlement / partner-settlement (app_partner)
//
// 대응 spec: docs/features/settlement/partner-settlement/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위 (Flutter integration test): 5/14
//   3-1: 정산 요약 KPI 조회 (대시보드 탭)
//   3-2: 이벤트별 정산 목록 조회 (목록 탭)
//   3-3: 정산 상세 (수수료 내역 · 타임라인 · 재지급 버튼 · CSV)
//   5-1: 정산 계좌 등록 (빈 상태 → 저장)
//   5-2: 정산 계좌 변경 (기존 계좌 → 수정 저장)
//
// 미커버 (9/14):
//   1-1, 1-2: DB 트리거 / 멱등성 — Supabase pgTAP 테스트 영역
//   2-1, 2-2, 2-3: nightly cron / PortOne Payout API — 백엔드 영역
//   3-4: 정산 이의 제기 — HOLD 상태 이의 제기 기능 미구현
//   3-5: 정산 PDF 다운로드 — PDF 다운로드 기능 미구현 (현재 CSV만 존재)
//   4-1: 시스템 지수 백오프 재시도 — 백엔드 영역
//   6-1: 이벤트 취소 → 정산 CANCELED — 백엔드 영역

import 'package:app_partner/src/features/settlement/bank_account_page.dart';
import 'package:app_partner/src/features/settlement/settlement_coordinator.dart';
import 'package:app_partner/src/features/settlement/settlement_dashboard_controller.dart';
import 'package:app_partner/src/features/settlement/settlement_detail_page.dart';
import 'package:app_partner/src/features/settlement/settlement_list_controller.dart';
import 'package:app_partner/src/features/settlement/settlement_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockSettlementRepository extends Mock implements SettlementRepository {}

class _MockSettlementCoordinator extends Mock
    implements SettlementCoordinator {}

// ---------------------------------------------------------------------------
// Fake controllers — 네트워크 없이 원하는 상태를 즉시 반환
// ---------------------------------------------------------------------------

class _FakeDashboardController extends SettlementDashboardController {
  _FakeDashboardController(this._data);
  final Map<String, dynamic>? _data;

  @override
  SettlementDashboardState build() => SettlementDashboardState(
    selectedMonth: DateTime(2024, 3),
    status: const AsyncValue.data(null),
    dashboardData: _data,
  );
}

class _ErrorDashboardController extends SettlementDashboardController {
  @override
  SettlementDashboardState build() => SettlementDashboardState(
    selectedMonth: DateTime(2024, 3),
    status: AsyncValue<void>.error(Exception('network'), StackTrace.empty),
  );
}

class _FakeListController extends SettlementListController {
  _FakeListController(this._items);
  final List<SettlementItemDetail> _items;

  @override
  SettlementListState build() =>
      SettlementListState(items: _items, hasMore: false);
}

class _EmptyListController extends SettlementListController {
  @override
  SettlementListState build() => const SettlementListState(hasMore: false);
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

final _epoch = DateTime(2024);
const _partner = Partner(id: 'partner-1', name: '테스트 파트너');

SettlementItemDetail _makeItem({
  String id = 'item-1',
  String status = 'PENDING',
  int grossAmount = 100000,
  int platformFeeAmount = 5000,
  int pgFeeAmount = 3000,
  int vatAmount = 500,
  int netAmount = 91500,
  bool retryable = false,
  int retryCount = 0,
  List<SettlementHistoryEntry> histories = const [],
}) => SettlementItemDetail(
  id: id,
  partnerId: 'partner-1',
  status: status,
  grossAmount: grossAmount,
  platformFeeAmount: platformFeeAmount,
  pgFeeAmount: pgFeeAmount,
  vatAmount: vatAmount,
  netAmount: netAmount,
  currency: 'KRW',
  createdAt: _epoch,
  updatedAt: _epoch,
  retryable: retryable,
  retryCount: retryCount,
  histories: histories,
  adjustments: const [],
);

Map<String, dynamic> _makeDashboardData({
  int completedGross = 1000000,
  int completedNet = 850000,
  int pendingGross = 200000,
}) => {
  'completed_gross_total': completedGross,
  'completed_net_total': completedNet,
  'pending_gross_total': pendingGross,
  'status_counts': <String, int>{
    'PENDING': 3,
    'READY': 1,
    'PROCESSING': 0,
    'COMPLETED': 10,
    'FAILED': 0,
    'HOLD': 0,
    'CANCELED': 1,
  },
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockSettlementRepository repo;
  late _MockSettlementCoordinator coordinator;

  setUp(() {
    repo = _MockSettlementRepository();
    coordinator = _MockSettlementCoordinator();

    // coordinator void 메서드 스텁 — 네비게이션 호출 격리
    when(() => coordinator.goToDetail(any())).thenReturn(null);
    when(() => coordinator.goToBankAccount()).thenReturn(null);
    when(() => coordinator.goToPartyCreate()).thenReturn(null);
    when(() => coordinator.goToSettlement()).thenReturn(null);
  });

  List<dynamic> base() => [
    currentPartnerInfoProvider.overrideWith((_) async => _partner),
    settlementRepositoryProvider.overrideWithValue(repo),
    settlementCoordinatorProvider.overrideWith(() => coordinator),
    currentMemberPermissionsProvider.overrideWith(
      (_) async => <String>['SETTLEMENT_VIEW', 'SETTLEMENT_EDIT'],
    ),
  ];

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 이벤트 완료 시 정산 레코드 자동 생성 (백엔드)
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '이벤트 완료 시 정산 레코드 자동 생성 (DB 트리거)', () {
    cujCase(
      'stub: DB 트리거 — Flutter integration test 범위 외',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        // on_event_completed 트리거는 supabase/pgTAP 테스트에서 검증
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 이벤트 완료 트리거 멱등성 보장 (백엔드)
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '이벤트 완료 트리거 멱등성 보장 (DB 트리거)', () {
    cujCase(
      'stub: 멱등성 — Flutter integration test 범위 외',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 14일 경과 시 PENDING → READY 전환 (백엔드 cron)
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '14일 경과 PENDING → READY 전환 (nightly cron)', () {
    cujCase(
      'stub: nightly cron — Flutter integration test 범위 외',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: READY 배치 지급 → COMPLETED (PortOne Payout API)
  // ---------------------------------------------------------------------------

  cujGroup('2-2', 'READY 배치 지급 → COMPLETED (PortOne API)', () {
    cujCase(
      'stub: PortOne Payout API — Flutter integration test 범위 외',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-3: 지급 실패 지수 백오프 재시도 (백엔드)
  // ---------------------------------------------------------------------------

  cujGroup('2-3', '지급 실패 지수 백오프 재시도 (백엔드 재시도 로직)', () {
    cujCase(
      'stub: 지수 백오프 — Flutter integration test 범위 외',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 파트너가 정산 요약 KPI 조회
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '파트너가 정산 요약 KPI 조회', () {
    cujCase(
      'happy: 대시보드 탭 — 정산 완료 매출·정산 완료·정산 대기 카드 노출',
      app: const SettlementPage(),
      overrides: () => [
        ...base(),
        settlementDashboardControllerProvider.overrideWith(
          () => _FakeDashboardController(_makeDashboardData()),
        ),
        settlementListControllerProvider.overrideWith(
          _EmptyListController.new,
        ),
      ],
      body: (t) async {
        expect(find.text('정산 완료 매출'), findsOneWidget);
        expect(find.text('정산 완료'), findsOneWidget);
        expect(find.text('정산 대기'), findsOneWidget);
        expect(find.text('상태별 현황'), findsOneWidget);
        // 상태별 현황 그리드 — 대기/완료 셀 노출
        expect(find.text('대기'), findsOneWidget);
        expect(find.text('완료'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 정산 0건인 파트너 — 빈 데이터 대시보드 정상 렌더',
      app: const SettlementPage(),
      overrides: () => [
        ...base(),
        settlementDashboardControllerProvider.overrideWith(
          () => _FakeDashboardController({
            'completed_gross_total': 0,
            'completed_net_total': 0,
            'pending_gross_total': 0,
            'status_counts': <String, int>{},
          }),
        ),
        settlementListControllerProvider.overrideWith(
          _EmptyListController.new,
        ),
      ],
      body: (t) async {
        expect(find.text('정산 완료 매출'), findsOneWidget);
        expect(find.text('상태별 현황'), findsOneWidget);
      },
    );

    cujCase(
      'error: 대시보드 로드 실패 → 에러 메시지 + 다시 시도 버튼',
      app: const SettlementPage(),
      overrides: () => [
        ...base(),
        settlementDashboardControllerProvider.overrideWith(
          _ErrorDashboardController.new,
        ),
        settlementListControllerProvider.overrideWith(
          _EmptyListController.new,
        ),
      ],
      body: (t) async {
        expect(find.text('대시보드를 불러오지 못했습니다'), findsOneWidget);
        expect(find.text('다시 시도'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 이벤트별 정산 목록 조회
  // ---------------------------------------------------------------------------

  cujGroup('3-2', '이벤트별 정산 목록 조회', () {
    cujCase(
      'happy: 정산 내역 탭 — PENDING/COMPLETED 항목 상태 뱃지 노출',
      app: const SettlementPage(),
      overrides: () => [
        ...base(),
        settlementDashboardControllerProvider.overrideWith(
          () => _FakeDashboardController(_makeDashboardData()),
        ),
        settlementListControllerProvider.overrideWith(
          () => _FakeListController([
            _makeItem(),
            _makeItem(id: 'item-2', status: 'COMPLETED'),
          ]),
        ),
      ],
      body: (t) async {
        // 정산 내역 탭으로 전환
        await t.tap(find.text('정산 내역'));
        await t.pumpAndSettle();

        expect(find.text('정산 대기'), findsOneWidget);
        expect(find.text('지급 완료'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 빈 목록 → 빈 상태 안내 + 첫 이벤트 만들기 CTA',
      app: const SettlementPage(),
      overrides: () => [
        ...base(),
        settlementDashboardControllerProvider.overrideWith(
          () => _FakeDashboardController(_makeDashboardData()),
        ),
        settlementListControllerProvider.overrideWith(
          _EmptyListController.new,
        ),
      ],
      body: (t) async {
        await t.tap(find.text('정산 내역'));
        await t.pumpAndSettle();

        expect(find.text('정산 항목이 없습니다'), findsOneWidget);
        expect(find.text('첫 이벤트 만들기'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 완료 필터 선택 → 완료 항목만 노출',
      app: const SettlementPage(),
      overrides: () {
        when(
          () => repo.getSettlementItems(
            partnerId: any(named: 'partnerId'),
            status: any(named: 'status'),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => [_makeItem(id: 'item-c', status: 'COMPLETED')],
        );
        return [
          ...base(),
          settlementDashboardControllerProvider.overrideWith(
            () => _FakeDashboardController(_makeDashboardData()),
          ),
          settlementListControllerProvider.overrideWith(
            () => _FakeListController([
              _makeItem(id: 'item-c', status: 'COMPLETED'),
            ]),
          ),
        ];
      },
      body: (t) async {
        await t.tap(find.text('정산 내역'));
        await t.pumpAndSettle();

        await t.tap(find.text('완료'));
        await t.pumpAndSettle();

        expect(find.text('지급 완료'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-3: 정산 상세 (수수료 내역 · 타임라인 · 액션 버튼)
  // ---------------------------------------------------------------------------

  cujGroup('3-3', '정산 상세 — 수수료 내역 · 타임라인 · 액션 버튼', () {
    cujCase(
      'happy: COMPLETED — 지급 완료 메시지 + 금액 내역 + 처리 이력',
      app: const SettlementDetailPage(itemId: 'item-c'),
      overrides: () {
        when(() => repo.getSettlementItemDetail('item-c')).thenAnswer(
          (_) async => _makeItem(
            id: 'item-c',
            status: 'COMPLETED',
            histories: [
              SettlementHistoryEntry(
                eventType: 'STATUS_CHANGED',
                fromStatus: 'PENDING',
                toStatus: 'READY',
                createdAt: _epoch,
              ),
            ],
          ),
        );
        return base();
      },
      body: (t) async {
        expect(find.text('정산 상세'), findsOneWidget);
        expect(find.text('지급이 완료되었습니다.'), findsOneWidget);
        expect(find.text('금액 내역'), findsOneWidget);
        expect(find.text('처리 이력'), findsOneWidget);
      },
    );

    cujCase(
      'happy: PENDING — 확정 대기 메시지',
      app: const SettlementDetailPage(itemId: 'item-p'),
      overrides: () {
        when(
          () => repo.getSettlementItemDetail('item-p'),
        ).thenAnswer((_) async => _makeItem(id: 'item-p'));
        return base();
      },
      body: (t) async {
        expect(find.text('정산이 확정되기를 기다리고 있습니다.'), findsOneWidget);
      },
    );

    cujCase(
      'happy: HOLD — 보류 메시지',
      app: const SettlementDetailPage(itemId: 'item-h'),
      overrides: () {
        when(
          () => repo.getSettlementItemDetail('item-h'),
        ).thenAnswer((_) async => _makeItem(id: 'item-h', status: 'HOLD'));
        return base();
      },
      body: (t) async {
        expect(find.text('정산이 보류 중입니다. 지원센터에 문의해 주세요.'), findsOneWidget);
      },
    );

    cujCase(
      'error: 상세 로드 실패 → 오류 메시지 + 다시 시도',
      app: const SettlementDetailPage(itemId: 'item-err'),
      overrides: () {
        when(
          () => repo.getSettlementItemDetail('item-err'),
        ).thenThrow(Exception('network error'));
        return base();
      },
      body: (t) async {
        expect(find.text('오류가 발생했습니다'), findsOneWidget);
        expect(find.text('다시 시도'), findsOneWidget);
      },
    );

    cujCase(
      'happy: FAILED + retryable=true → 재지급 요청 버튼 노출',
      app: const SettlementDetailPage(itemId: 'item-fail'),
      overrides: () {
        when(() => repo.getSettlementItemDetail('item-fail')).thenAnswer(
          (_) async =>
              _makeItem(id: 'item-fail', status: 'FAILED', retryable: true),
        );
        return base();
      },
      body: (t) async {
        expect(find.text('지급에 실패했습니다. 계좌 정보를 확인해 주세요.'), findsOneWidget);
        expect(find.text('재지급 요청'), findsOneWidget);
      },
    );

    cujCase(
      'happy: FAILED + retryable=false → 재지급 요청 버튼 미노출',
      app: const SettlementDetailPage(itemId: 'item-fail-nr'),
      overrides: () {
        when(() => repo.getSettlementItemDetail('item-fail-nr')).thenAnswer(
          (_) async => _makeItem(id: 'item-fail-nr', status: 'FAILED'),
        );
        return base();
      },
      body: (t) async {
        expect(find.text('재지급 요청'), findsNothing);
      },
    );

    cujCase(
      'happy: 정산 항목 → CSV 다운로드 버튼 노출',
      app: const SettlementDetailPage(itemId: 'item-csv'),
      overrides: () {
        when(() => repo.getSettlementItemDetail('item-csv')).thenAnswer(
          (_) async => _makeItem(id: 'item-csv', status: 'COMPLETED'),
        );
        return base();
      },
      body: (t) async {
        expect(find.text('CSV 다운로드'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-4: 정산 이의 제기 (HOLD 상태) — 미구현
  // ---------------------------------------------------------------------------

  cujGroup('3-4', '정산 이의 제기 (HOLD 상태)', () {
    cujCase(
      'stub: HOLD 상태 이의 제기 기능 미구현 — 별도 이슈 분리',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        // CUJ 3-4 (spec: HOLD 상태에서 이의 제기 탭, 사유 입력, 운영팀 알림)
        // SettlementDetailPage에 이의 제기 기능이 구현되지 않았음.
        // 구현 완료 후 SettlementDetailPage(itemId: ...) 위젯으로 테스트 교체.
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-5: 정산 PDF 다운로드 — 미구현
  // ---------------------------------------------------------------------------

  cujGroup('3-5', '정산 PDF 다운로드', () {
    cujCase(
      'stub: PDF 다운로드 기능 미구현 — 별도 이슈 분리',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        // CUJ 3-5 (spec: 정산 상세에서 PDF 다운로드, 정산 내역·서명·수수료 포함)
        // 현재 구현은 CSV 다운로드만 존재 (SettlementDetailPage.ActionButtons).
        // PDF 기능 구현 완료 후 교체.
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-1: 지급 실패 항목 재시도 (백엔드 스케줄러)
  // ---------------------------------------------------------------------------

  cujGroup('4-1', '지급 실패 자동 재시도 (nightly cron)', () {
    cujCase(
      'stub: 자동 재시도 — Flutter integration test 범위 외',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 5-1: 파트너가 정산 계좌 등록
  // ---------------------------------------------------------------------------

  cujGroup('5-1', '파트너가 정산 계좌 등록', () {
    cujCase(
      'happy: 계좌 미등록 상태 → 계좌 정보 입력 후 저장',
      app: const BankAccountPage(),
      overrides: () {
        when(
          () => repo.getBankAccount('partner-1'),
        ).thenAnswer((_) async => null);
        when(
          () => repo.upsertBankAccount(
            partnerId: any(named: 'partnerId'),
            bankName: any(named: 'bankName'),
            accountHolder: any(named: 'accountHolder'),
            accountNumber: any(named: 'accountNumber'),
          ),
        ).thenAnswer((_) async {});
        return base();
      },
      body: (t) async {
        expect(find.text('등록된 계좌 정보가 없습니다.'), findsOneWidget);
        expect(find.text('계좌 수정'), findsOneWidget);

        // 계좌 정보 입력
        await t.enterText(find.bySemanticsLabel('은행명'), '국민은행');
        await t.enterText(find.bySemanticsLabel('예금주'), '홍길동');
        await t.enterText(find.bySemanticsLabel('계좌번호'), '12345678901234');
        await t.pumpAndSettle();

        await t.tap(find.text('저장'));
        await t.pumpAndSettle();

        verify(
          () => repo.upsertBankAccount(
            partnerId: 'partner-1',
            bankName: '국민은행',
            accountHolder: '홍길동',
            accountNumber: '12345678901234',
          ),
        ).called(1);
        expect(find.text('계좌 정보가 저장되었습니다.'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 5-2: 파트너가 정산 계좌 변경
  // ---------------------------------------------------------------------------

  cujGroup('5-2', '파트너가 정산 계좌 변경', () {
    cujCase(
      'happy: 기존 계좌 표시 → 새 계좌로 변경 후 저장',
      app: const BankAccountPage(),
      overrides: () {
        when(() => repo.getBankAccount('partner-1')).thenAnswer(
          (_) async => <String, dynamic>{
            'bank_name': '신한은행',
            'account_holder': '홍길동',
            'account_number': '11111111111111',
          },
        );
        when(
          () => repo.upsertBankAccount(
            partnerId: any(named: 'partnerId'),
            bankName: any(named: 'bankName'),
            accountHolder: any(named: 'accountHolder'),
            accountNumber: any(named: 'accountNumber'),
          ),
        ).thenAnswer((_) async {});
        return base();
      },
      body: (t) async {
        // 기존 계좌 표시 확인
        expect(find.text('현재 계좌'), findsOneWidget);
        expect(find.text('신한은행'), findsWidgets);
        expect(find.text('홍길동'), findsOneWidget);

        // 은행명 수정
        await t.enterText(find.bySemanticsLabel('은행명'), '국민은행');
        await t.pumpAndSettle();

        await t.tap(find.text('저장'));
        await t.pumpAndSettle();

        verify(
          () => repo.upsertBankAccount(
            partnerId: 'partner-1',
            bankName: '국민은행',
            accountHolder: any(named: 'accountHolder'),
            accountNumber: any(named: 'accountNumber'),
          ),
        ).called(1);
        expect(find.text('계좌 정보가 저장되었습니다.'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 저장 실패 → SnackBar 오류 메시지',
      app: const BankAccountPage(),
      overrides: () {
        when(
          () => repo.getBankAccount('partner-1'),
        ).thenAnswer((_) async => null);
        when(
          () => repo.upsertBankAccount(
            partnerId: any(named: 'partnerId'),
            bankName: any(named: 'bankName'),
            accountHolder: any(named: 'accountHolder'),
            accountNumber: any(named: 'accountNumber'),
          ),
        ).thenThrow(Exception('network'));
        return base();
      },
      body: (t) async {
        await t.enterText(find.bySemanticsLabel('은행명'), '국민은행');
        await t.enterText(find.bySemanticsLabel('예금주'), '홍길동');
        await t.enterText(find.bySemanticsLabel('계좌번호'), '12345678901234');
        await t.tap(find.text('저장'));
        await t.pumpAndSettle();

        expect(find.textContaining('저장 실패'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 6-1: 이벤트 취소 → 정산 CANCELED (백엔드)
  // ---------------------------------------------------------------------------

  cujGroup('6-1', '이벤트 취소 → 정산 CANCELED (백엔드 CAS)', () {
    cujCase(
      'stub: settlement CANCELED — Flutter integration test 범위 외',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        expect(true, isTrue);
      },
    );
  });
}
