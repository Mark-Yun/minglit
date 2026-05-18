// CUJ tests — account / partner-account-deletion
//
// 대응 spec: docs/features/account/account-deletion/spec.md (파트너 시나리오)
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가.

import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:app_partner/src/features/account_deletion/partner_account_deletion_guard.dart';
import 'package:app_partner/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:app_partner/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../_engine/cuj_test.dart';

class _MockCoordinator extends Mock implements AccountDeletionCoordinator {}

class _MockUser extends Mock implements User {}

class _FakeWithdrawalReason extends Fake implements WithdrawalReason {}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _FakeAccountRepository extends AccountRepository {
  _FakeAccountRepository() : super(_FakeSupabaseClient());

  @override
  Future<DeletionStatus?> getDeletionStatus() async => null;

  @override
  Future<void> reauthenticate(String? password) async {}

  @override
  Future<DeletionStatus> deleteAccount(WithdrawalReason? reason) async =>
      DeletionStatus.fromDeletedAt(DateTime.now());
}

_MockUser _socialUser() {
  final user = _MockUser();
  when(() => user.appMetadata).thenReturn(const {'provider': 'google'});
  when(() => user.identities).thenReturn(const []);
  return user;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeWithdrawalReason());
  });

  late _MockCoordinator coordinator;

  setUp(() {
    coordinator = _MockCoordinator();
  });

  List<dynamic> base() => [
    accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
  ];

  cujGroup('1-1', '탈퇴 사유 선택 후 다음 단계 진입', () {
    cujCase(
      'happy: 사유 선택 → 다음 → pushInfo(reason: ...)',
      app: const DeletionReasonPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('더 이상 운영하지 않아요'));
        await t.pumpAndSettle();

        // 다음 버튼 활성 확인
        final nextBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '다음'),
        );
        expect(nextBtn.onPressed, isNotNull);

        await t.tap(find.text('다음'));
        await t.pumpAndSettle();

        verify(
          () => coordinator.pushInfo(reason: any(named: 'reason')),
        ).called(1);
      },
    );

    cujCase(
      'happy: 선택 없이 계속하기 → pushInfo(reason: null)',
      app: const DeletionReasonPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('선택하지 않고 계속하기'));
        await t.pumpAndSettle();

        // reason 없이 호출
        verify(() => coordinator.pushInfo()).called(1);
      },
    );

    cujCase(
      'edge: 사유 미선택 → 다음 비활성',
      app: const DeletionReasonPage(),
      overrides: base,
      body: (t) async {
        final nextBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '다음'),
        );
        expect(nextBtn.onPressed, isNull);
        verifyNever(
          () => coordinator.pushInfo(reason: any(named: 'reason')),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 파트너가 탈퇴 시도 시 차단 조건 검사
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '파트너가 탈퇴 시도 시 차단 조건 검사', () {
    List<dynamic> blockedBase({
      int activeEvents = 0,
      int unsettled = 0,
      int pendingRefunds = 0,
    }) =>
        [
          currentUserProvider.overrideWith((_) => _socialUser()),
          authStateChangesProvider.overrideWith((_) => const Stream.empty()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
          partnerAccountDeletionGuardProvider.overrideWith(
            (_) async => PartnerAccountDeletionGuard(
              activeEventCount: activeEvents,
              unsettledSettlementCount: unsettled,
              pendingRefundCount: pendingRefunds,
            ),
          ),
        ];

    cujCase(
      'happy: 활성 이벤트 있음 → 탈퇴 요청 비활성 + 차단 카드 표시 (FR-10)',
      app: const DeletionVerifyPage(),
      overrides: () => blockedBase(activeEvents: 2),
      body: (t) async {
        await t.pumpAndSettle();

        // 차단 항목 표시 확인 (FR-10)
        expect(find.textContaining('활성 이벤트'), findsOneWidget);
        expect(find.text('이벤트 관리로 이동'), findsOneWidget);

        // 탈퇴 요청 버튼 비활성 (FR-10: 하나라도 있으면 차단)
        final submitBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '탈퇴 요청'),
        );
        expect(submitBtn.onPressed, isNull);
      },
    );

    cujCase(
      'happy: 미정산 건 있음 → 탈퇴 요청 비활성 + 정산 바로가기 표시 (FR-11)',
      app: const DeletionVerifyPage(),
      overrides: () => blockedBase(unsettled: 3),
      body: (t) async {
        await t.pumpAndSettle();

        expect(find.textContaining('미정산 건'), findsOneWidget);
        expect(find.text('정산 페이지로 이동'), findsOneWidget);

        final submitBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '탈퇴 요청'),
        );
        expect(submitBtn.onPressed, isNull);
      },
    );

    cujCase(
      'happy: 환불 대기 있음 → 탈퇴 요청 비활성 + 신청 관리 바로가기 표시 (FR-11)',
      app: const DeletionVerifyPage(),
      overrides: () => blockedBase(pendingRefunds: 1),
      body: (t) async {
        await t.pumpAndSettle();

        expect(find.textContaining('환불 대기 건'), findsOneWidget);
        expect(find.text('신청 관리로 이동'), findsOneWidget);

        final submitBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '탈퇴 요청'),
        );
        expect(submitBtn.onPressed, isNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: 파트너가 차단 항목 해결 후 정상 탈퇴
  // ---------------------------------------------------------------------------

  cujGroup('2-2', '파트너가 차단 항목 해결 후 정상 탈퇴', () {
    List<dynamic> clearedBase() => [
      currentUserProvider.overrideWith((_) => _socialUser()),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
      accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
      partnerAccountDeletionGuardProvider.overrideWith(
        (_) async => const PartnerAccountDeletionGuard(),
      ),
    ];

    cujCase(
      'happy: 차단 항목 없음 → 탈퇴 요청 활성 + 통과 카드 표시 (FR-12)',
      app: const DeletionVerifyPage(),
      overrides: clearedBase,
      body: (t) async {
        await t.pumpAndSettle();

        // 차단 없음 안내 카드 표시 (FR-12: 차단 통과)
        expect(find.text('탈퇴 요청을 진행할 수 있어요'), findsOneWidget);

        // 탈퇴 요청 버튼 활성 (FR-10: 차단 항목 없으면 진행 가능)
        final submitBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '탈퇴 요청'),
        );
        expect(submitBtn.onPressed, isNotNull);
      },
    );
  });
}
