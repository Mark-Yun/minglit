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

class _MockSettlementRepository extends Mock implements SettlementRepository {}

SettlementDashboardState _dashboardSeed = SettlementDashboardState(
  selectedMonth: DateTime(2026, 5),
  status: const AsyncValue.data(null),
  dashboardData: const {
    'status_counts': {
      'PENDING': 1,
      'READY': 1,
      'PROCESSING': 1,
      'COMPLETED': 1,
      'FAILED': 1,
      'HOLD': 1,
      'CANCELED': 1,
    },
    'completed_gross_total': 120000,
    'completed_net_total': 100000,
    'pending_gross_total': 30000,
    'total_items': 7,
  },
);

SettlementListState _listSeed = const SettlementListState();

class _FakeSettlementDashboardController extends SettlementDashboardController {
  @override
  SettlementDashboardState build() => _dashboardSeed;
}

class _FakeSettlementListController extends SettlementListController {
  @override
  SettlementListState build() => _listSeed;
}

class _FakeSettlementCoordinator extends SettlementCoordinator {
  int goToBankAccountCalls = 0;
  int goToPartyCreateCalls = 0;
  int retryPayoutCalls = 0;
  final List<String> goToDetailIds = <String>[];
  (String payoutId, String partnerId)? lastRetry;

  @override
  void build() {}

  @override
  void goToBankAccount() {
    goToBankAccountCalls++;
  }

  @override
  void goToPartyCreate() {
    goToPartyCreateCalls++;
  }

  @override
  void goToDetail(String itemId) {
    goToDetailIds.add(itemId);
  }

  @override
  Future<void> retryPayout(
    BuildContext context, {
    required String payoutId,
    required String partnerId,
  }) async {
    retryPayoutCalls++;
    lastRetry = (payoutId, partnerId);
  }
}

SettlementItemDetail _detail({
  required String id,
  required String status,
  bool retryable = false,
  String? payoutId,
  int netAmount = 93000,
  DateTime? createdAt,
  List<SettlementHistoryEntry> histories = const [],
}) {
  final now = createdAt ?? DateTime(2026, 5, 20, 12);
  return SettlementItemDetail(
    id: id,
    partnerId: 'partner-1',
    status: status,
    grossAmount: 100000,
    platformFeeAmount: 5000,
    pgFeeAmount: 1000,
    vatAmount: 500,
    netAmount: netAmount,
    currency: 'KRW',
    createdAt: now,
    updatedAt: now,
    retryable: retryable,
    retryCount: 0,
    payoutId: payoutId,
    histories: histories,
    adjustments: const [],
  );
}

List<dynamic> _baseOverrides({
  required _MockSettlementRepository repo,
  required _FakeSettlementCoordinator coordinator,
  SettlementDashboardState? dashboardState,
  SettlementListState? listState,
  List<String>? permissions,
}) {
  _dashboardSeed =
      dashboardState ??
      SettlementDashboardState(
        selectedMonth: DateTime(2026, 5),
        status: const AsyncValue.data(null),
        dashboardData: const {
          'status_counts': {
            'PENDING': 1,
            'READY': 1,
            'PROCESSING': 1,
            'COMPLETED': 1,
            'FAILED': 1,
            'HOLD': 1,
            'CANCELED': 1,
          },
          'completed_gross_total': 120000,
          'completed_net_total': 100000,
          'pending_gross_total': 30000,
          'total_items': 7,
        },
      );
  _listSeed = listState ?? const SettlementListState();

  return [
    settlementRepositoryProvider.overrideWithValue(repo),
    currentPartnerInfoProvider.overrideWith(
      (ref) async => const Partner(id: 'partner-1', name: '테스트 파트너'),
    ),
    currentMemberPermissionsProvider.overrideWith(
      (ref) async =>
          permissions ?? const ['SETTLEMENT_VIEW', 'SETTLEMENT_EDIT'],
    ),
    settlementDashboardControllerProvider.overrideWith(
      _FakeSettlementDashboardController.new,
    ),
    settlementListControllerProvider.overrideWith(
      _FakeSettlementListController.new,
    ),
    settlementCoordinatorProvider.overrideWith(() => coordinator),
  ];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockSettlementRepository repo;
  late _FakeSettlementCoordinator coordinator;

  setUp(() {
    repo = _MockSettlementRepository();
    coordinator = _FakeSettlementCoordinator();

    when(
      () => repo.getSettlementItemDetail(any()),
    ).thenAnswer((_) async => _detail(id: 'item-1', status: 'COMPLETED'));
    when(
      () => repo.upsertBankAccount(
        partnerId: any(named: 'partnerId'),
        bankName: any(named: 'bankName'),
        accountHolder: any(named: 'accountHolder'),
        accountNumber: any(named: 'accountNumber'),
      ),
    ).thenAnswer((_) async {});
    when(() => repo.getBankAccount(any())).thenAnswer((_) async => null);
  });

  cujGroup('1-1', '이벤트 완료 시 정산 레코드 자동 생성', () {
    cujCase(
      'happy: 정산 목록에 PENDING 항목이 렌더링된다',
      app: const SettlementPage(initialIndex: 1),
      overrides: () => _baseOverrides(
        repo: repo,
        coordinator: coordinator,
        listState: SettlementListState(
          items: [_detail(id: 'pending-1', status: 'PENDING')],
          hasMore: false,
        ),
      ),
      body: (t) async {
        expect(find.text('정산 항목'), findsOneWidget);
        expect(find.text('정산 대기'), findsOneWidget);
      },
    );
  });

  cujGroup('1-2', '이벤트 완료 트리거 멱등성 보장', () {
    cujCase(
      'happy: 동일 이벤트 ID 데이터가 중복 없이 1건만 표시된다',
      app: const SettlementPage(initialIndex: 1),
      overrides: () => _baseOverrides(
        repo: repo,
        coordinator: coordinator,
        listState: SettlementListState(
          items: [
            _detail(
              id: 'same-event',
              status: 'PENDING',
              netAmount: 77777,
              createdAt: DateTime(2026, 5, 12, 9),
            ),
            _detail(
              id: 'same-event',
              status: 'PENDING',
              netAmount: 77777,
              createdAt: DateTime(2026, 5, 12, 9),
            ),
          ],
          hasMore: false,
        ),
      ),
      body: (t) async {
        expect(find.text('정산 항목'), findsOneWidget);
        expect(find.text('2026-05-12'), findsOneWidget);
        expect(find.text('₩77,777'), findsOneWidget);
      },
    );
  });

  cujGroup('2-1', '14일 경과 시 PENDING → READY 전환', () {
    cujCase(
      'happy: 대시보드 상태 요약에서 READY 카운트가 노출된다',
      app: const SettlementPage(),
      overrides: () => _baseOverrides(
        repo: repo,
        coordinator: coordinator,
      ),
      body: (t) async {
        expect(find.text('상태별 현황'), findsOneWidget);
        expect(find.text('확정'), findsOneWidget);
      },
    );
  });

  cujGroup('2-2', 'READY 배치 지급 → COMPLETED', () {
    cujCase(
      'happy: COMPLETED 상세에서 완료 메시지를 보여준다',
      app: const SettlementDetailPage(itemId: 'item-1'),
      overrides: () => _baseOverrides(
        repo: repo,
        coordinator: coordinator,
      ),
      body: (t) async {
        expect(find.text('지급이 완료되었습니다.'), findsOneWidget);
        expect(find.text('금액 내역'), findsOneWidget);
      },
    );
  });

  cujGroup('2-3', '지급 실패 지수 백오프 재시도', () {
    cujCase(
      'happy: FAILED + retryable 항목에서 재지급 요청 버튼을 실행한다',
      app: const SettlementDetailPage(itemId: 'item-1'),
      overrides: () {
        when(
          () => repo.getSettlementItemDetail(any()),
        ).thenAnswer(
          (_) async => _detail(
            id: 'failed-1',
            status: 'FAILED',
            retryable: true,
            payoutId: 'payout-1',
          ),
        );
        return _baseOverrides(repo: repo, coordinator: coordinator);
      },
      body: (t) async {
        await t.tap(find.text('재지급 요청'));
        await t.pumpAndSettle();

        expect(coordinator.retryPayoutCalls, 1);
        expect(coordinator.lastRetry, ('payout-1', 'partner-1'));
      },
    );
  });

  cujGroup('3-1', '파트너가 정산 요약 KPI 조회', () {
    cujCase(
      'happy: 대시보드 KPI 카드(정산 완료 매출/정산 대기)가 표시된다',
      app: const SettlementPage(),
      overrides: () => _baseOverrides(
        repo: repo,
        coordinator: coordinator,
      ),
      body: (t) async {
        expect(find.text('정산 완료 매출'), findsOneWidget);
        expect(find.text('정산 대기'), findsOneWidget);
      },
    );
  });

  cujGroup('3-2', '이벤트별 정산 목록 조회', () {
    cujCase(
      'happy: 목록 카드 탭 시 상세 진입 coordinator가 호출된다',
      app: const SettlementPage(initialIndex: 1),
      overrides: () => _baseOverrides(
        repo: repo,
        coordinator: coordinator,
        listState: SettlementListState(
          items: [_detail(id: 'detail-1', status: 'READY')],
          hasMore: false,
        ),
      ),
      body: (t) async {
        await t.tap(find.text('정산 항목'));
        await t.pumpAndSettle();

        expect(coordinator.goToDetailIds, ['detail-1']);
      },
    );
  });

  cujGroup('3-3', '정산 상세 (수수료 내역·타임라인)', () {
    cujCase(
      'happy: 상세 화면에서 수수료 항목과 상태 타임라인을 표시한다',
      app: const SettlementDetailPage(itemId: 'item-1'),
      overrides: () {
        when(
          () => repo.getSettlementItemDetail(any()),
        ).thenAnswer(
          (_) async => _detail(
            id: 'timeline-1',
            status: 'PROCESSING',
            histories: [
              SettlementHistoryEntry(
                eventType: 'STATUS_CHANGED',
                fromStatus: 'READY',
                toStatus: 'PROCESSING',
                createdAt: DateTime(2026, 5, 20, 10),
              ),
            ],
          ),
        );
        return _baseOverrides(repo: repo, coordinator: coordinator);
      },
      body: (t) async {
        expect(find.text('금액 내역'), findsOneWidget);
        expect(find.text('처리 이력'), findsOneWidget);
        expect(find.textContaining('READY → PROCESSING'), findsOneWidget);
      },
    );
  });

  cujGroup('3-4', '정산 이의 제기', () {
    cujCase(
      'edge: HOLD 상태 상세에서 보류 안내 메시지를 노출한다',
      app: const SettlementDetailPage(itemId: 'item-1'),
      overrides: () {
        when(
          () => repo.getSettlementItemDetail(any()),
        ).thenAnswer((_) async => _detail(id: 'hold-1', status: 'HOLD'));
        return _baseOverrides(repo: repo, coordinator: coordinator);
      },
      body: (t) async {
        expect(find.textContaining('정산이 보류 중입니다'), findsOneWidget);
      },
    );
  });

  cujGroup('3-5', '정산 PDF 다운로드', () {
    cujCase(
      'happy: 상세 화면에서 다운로드 액션 버튼이 노출된다',
      app: const SettlementDetailPage(itemId: 'item-1'),
      overrides: () => _baseOverrides(
        repo: repo,
        coordinator: coordinator,
      ),
      body: (t) async {
        expect(find.text('CSV 다운로드'), findsOneWidget);
      },
    );
  });

  cujGroup('4-1', '지급 실패 항목 재시도 (시스템)', () {
    cujCase(
      'happy: retryable FAILED 상태에서 재지급 요청 버튼이 활성 노출된다',
      app: const SettlementDetailPage(itemId: 'item-1'),
      overrides: () {
        when(
          () => repo.getSettlementItemDetail(any()),
        ).thenAnswer(
          (_) async => _detail(
            id: 'failed-2',
            status: 'FAILED',
            retryable: true,
            payoutId: 'payout-2',
          ),
        );
        return _baseOverrides(repo: repo, coordinator: coordinator);
      },
      body: (t) async {
        expect(find.text('재지급 요청'), findsOneWidget);
      },
    );
  });

  cujGroup('5-1', '파트너가 정산 계좌 등록', () {
    cujCase(
      'happy: 계좌 정보 입력 후 저장 시 upsertBankAccount 호출',
      app: const BankAccountPage(),
      overrides: () => _baseOverrides(
        repo: repo,
        coordinator: coordinator,
      ),
      body: (t) async {
        await t.enterText(find.widgetWithText(TextFormField, '은행명'), '국민은행');
        await t.enterText(find.widgetWithText(TextFormField, '예금주'), '홍길동');
        await t.enterText(
          find.widgetWithText(TextFormField, '계좌번호'),
          '1234567890',
        );
        await t.tap(find.text('저장'));
        await t.pumpAndSettle();

        verify(
          () => repo.upsertBankAccount(
            partnerId: 'partner-1',
            bankName: '국민은행',
            accountHolder: '홍길동',
            accountNumber: '1234567890',
          ),
        ).called(1);
      },
    );
  });

  cujGroup('5-2', '파트너가 정산 계좌 변경', () {
    cujCase(
      'happy: 기존 계좌를 수정 저장하면 변경된 값으로 저장된다',
      app: const BankAccountPage(),
      overrides: () {
        when(() => repo.getBankAccount(any())).thenAnswer(
          (_) async => {
            'bank_name': '신한은행',
            'account_holder': '기존예금주',
            'account_number': '111122223333',
          },
        );
        return _baseOverrides(repo: repo, coordinator: coordinator);
      },
      body: (t) async {
        await t.enterText(find.widgetWithText(TextFormField, '은행명'), '카카오뱅크');
        await t.enterText(find.widgetWithText(TextFormField, '예금주'), '변경예금주');
        await t.enterText(
          find.widgetWithText(TextFormField, '계좌번호'),
          '444455556666',
        );
        await t.tap(find.text('저장'));
        await t.pumpAndSettle();

        verify(
          () => repo.upsertBankAccount(
            partnerId: 'partner-1',
            bankName: '카카오뱅크',
            accountHolder: '변경예금주',
            accountNumber: '444455556666',
          ),
        ).called(1);
      },
    );
  });

  cujGroup('6-1', '이벤트 취소 → 정산 CANCELED', () {
    cujCase(
      'happy: CANCELED 상태 상세에서 취소 메시지가 표시된다',
      app: const SettlementDetailPage(itemId: 'item-1'),
      overrides: () {
        when(
          () => repo.getSettlementItemDetail(any()),
        ).thenAnswer(
          (_) async => _detail(id: 'canceled-1', status: 'CANCELED'),
        );
        return _baseOverrides(repo: repo, coordinator: coordinator);
      },
      body: (t) async {
        expect(find.text('정산이 취소되었습니다.'), findsOneWidget);
      },
    );
  });
}
