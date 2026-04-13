// Ref #1339: IT-P10 — 파트너 계정 삭제 통합 테스트
//
// 검증 포인트:
// TC-P10-001: 미완료 이벤트 존재 시 탈퇴 차단 — 버튼 비활성화 + 차단 메시지 + 링크 표시
// TC-P10-002: 미정산 잔액 존재 시 탈퇴 차단 — 차단 메시지 + 정산 링크 표시
// TC-P10-003: 정상 탈퇴 플로우 — blockers 없는 상태, submit 버튼 활성화
// TC-P10-004: DeletionCompletePage — 7일 유예 기간 메시지 표시
import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:app_partner/src/features/account_deletion/partner_account_deletion_guard.dart';
import 'package:app_partner/src/features/account_deletion/ui/deletion_complete_page.dart';
import 'package:app_partner/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:app_partner/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountDeletionCoordinator extends Mock
    implements AccountDeletionCoordinator {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _FakeUser extends Fake implements User {}

User _makeUser() {
  return User(
    id: 'user-p10',
    appMetadata: const {
      'provider': 'email',
      'providers': ['email'],
    },
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime(2026).toIso8601String(),
    email: 'partner-p10@test.com',
    identities: const [],
  );
}

void main() {
  late _MockAccountDeletionCoordinator coordinator;
  late _MockAccountRepository accountRepository;
  late User user;

  setUpAll(() {
    registerFallbackValue(_FakeUser());
  });

  setUp(() {
    coordinator = _MockAccountDeletionCoordinator();
    accountRepository = _MockAccountRepository();
    user = _makeUser();

    when(
      () => accountRepository.getDeletionStatus(),
    ).thenAnswer((_) async => null);

    when(() => coordinator.goToSettlement()).thenReturn(null);
    when(() => coordinator.goToPartyList()).thenReturn(null);
    when(() => coordinator.goToApplications()).thenReturn(null);
    when(() => coordinator.goToHome()).thenReturn(null);
  });

  Widget buildVerifyPage({
    required PartnerAccountDeletionGuard guard,
    String? reasonCode,
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => user),
        accountRepositoryProvider.overrideWithValue(accountRepository),
        partnerAccountDeletionGuardProvider.overrideWith(
          (ref) async => guard,
        ),
        accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: DeletionVerifyPage(reasonCode: reasonCode),
      ),
    );
  }

  group('IT-P10: 파트너 계정 삭제', () {
    // ----------------------------------------------------------------
    // TC-P10-001: 미완료 이벤트 존재 시 탈퇴 차단
    // ----------------------------------------------------------------
    testWidgets('TC-P10-001: 활성 이벤트 존재 시 차단 메시지 + 버튼 비활성화 + 이벤트 관리 링크 표시', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildVerifyPage(
          guard: const PartnerAccountDeletionGuard(
            activeEventCount: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 차단 메시지 확인
      expect(find.text('활성 이벤트 2건'), findsOneWidget);

      // 제출 버튼 비활성화 확인
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      // 이벤트 관리 링크 탭
      await tester.tap(find.text('이벤트 관리로 이동'));
      verify(() => coordinator.goToPartyList()).called(1);
    });

    // ----------------------------------------------------------------
    // TC-P10-002: 미정산 잔액 존재 시 탈퇴 차단
    // ----------------------------------------------------------------
    testWidgets('TC-P10-002: 미정산 건 존재 시 차단 메시지 + 정산 페이지 링크 표시', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildVerifyPage(
          guard: const PartnerAccountDeletionGuard(
            unsettledSettlementCount: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 미정산 차단 메시지 확인
      expect(find.text('미정산 건 3건'), findsOneWidget);

      // 제출 버튼 비활성화 확인
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      // 정산 페이지 링크 탭
      await tester.tap(find.text('정산 페이지로 이동'));
      verify(() => coordinator.goToSettlement()).called(1);
    });

    testWidgets('TC-P10-002-V: 환불 대기 건 존재 시 차단 메시지 + 신청 관리 링크 표시', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildVerifyPage(
          guard: const PartnerAccountDeletionGuard(
            pendingRefundCount: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('환불 대기 건 1건'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.text('신청 관리로 이동'));
      verify(() => coordinator.goToApplications()).called(1);
    });

    testWidgets('TC-P10-002-V2: 복수 차단 조건 — 모든 항목 동시 표시', (tester) async {
      await tester.pumpWidget(
        buildVerifyPage(
          guard: const PartnerAccountDeletionGuard(
            activeEventCount: 1,
            unsettledSettlementCount: 2,
            pendingRefundCount: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('활성 이벤트 1건'), findsOneWidget);
      expect(find.text('미정산 건 2건'), findsOneWidget);
      expect(find.text('환불 대기 건 3건'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    // ----------------------------------------------------------------
    // TC-P10-003: 정상 탈퇴 플로우 — blockers 없는 상태
    // ----------------------------------------------------------------
    testWidgets('TC-P10-003: blockers 없을 때 "탈퇴 요청을 진행할 수 있어요" 메시지 + 버튼 활성화', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildVerifyPage(
          guard: const PartnerAccountDeletionGuard(),
        ),
      );
      await tester.pumpAndSettle();

      // 녹색 카드 메시지 확인
      expect(find.text('탈퇴 요청을 진행할 수 있어요'), findsOneWidget);

      // 제출 버튼 활성화 확인
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('TC-P10-003-V: DeletionReasonPage — 탈퇴 사유 옵션 목록 렌더링', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
          ],
          child: MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: const DeletionReasonPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 페이지 제목 확인
      expect(find.text('탈퇴 사유'), findsOneWidget);

      // 탈퇴 사유 옵션 중 하나 확인
      expect(find.text('더 이상 운영하지 않아요'), findsOneWidget);
    });

    // ----------------------------------------------------------------
    // TC-P10-004: DeletionCompletePage — 7일 유예 기간 메시지 표시
    // ----------------------------------------------------------------
    testWidgets('TC-P10-004: DeletionCompletePage — 7일 유예 기간 복구 가능 메시지 표시', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => user),
            accountRepositoryProvider.overrideWithValue(accountRepository),
            accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
            authControllerProvider.overrideWith(_FakeAuthController.new),
          ],
          child: MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: const DeletionCompletePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 탈퇴 완료 메시지 확인
      expect(find.text('탈퇴 요청이 완료됐어요'), findsOneWidget);

      // 7일 유예 기간 복구 가능 메시지 확인
      expect(
        find.text('지금부터 7일 안에 다시 로그인하면 계정을 복구할 수 있어요.'),
        findsOneWidget,
      );

      // 확인 버튼 존재 확인
      expect(find.text('확인'), findsOneWidget);
    });
  });
}

/// Fake AuthController — no-op stub (Fix #1073 참고).
class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {
    return null;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signInWithGoogle({String? redirectTo}) async {}

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithApple({String? redirectTo}) async {}

  @override
  Future<void> signInWithKakao({String? redirectTo}) async {}
}
