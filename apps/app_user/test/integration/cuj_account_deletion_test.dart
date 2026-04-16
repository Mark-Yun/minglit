// Ref #1313: IT-U06 — 계정 삭제 wizard 통합 테스트
//
// 검증 포인트:
// 1. 비로그인 사용자 탈퇴 페이지 접근 차단
// 2. 탈퇴 사유 선택 페이지 렌더링
// 3. 사유 선택 → 다음 버튼 활성화
// 4. 사유 없이 계속하기 → coordinator.pushInfo() 호출 (reason null)
// 5. 사유 선택 후 다음 → coordinator.pushInfo(reason: ...) 호출
// 6. 탈퇴 안내 페이지 렌더링 — 삭제 정보, 법정 보존 정보 섹션
// 7. 이메일 유저 → 비밀번호 입력 필드 표시
// 8. 소셜 유저 → 소셜 재인증 안내 표시
// 9. 빈 비밀번호 제출 → 에러 메시지 표시
// 10. 비밀번호 입력 후 탈퇴 요청 확인 → goComplete() 호출
// 11. 탈퇴 완료 페이지 렌더링
import 'dart:async';

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:app_user/src/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'utils/golden_capture.dart';
import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

/// 라우터 기반 테스트에서 반복되는 overrides 헬퍼.
List<dynamic> _deletionRouterOverrides() => [
  accountDeletionControllerProvider.overrideWith(_FakeDeletionController.new),
  accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
];

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final testUser = createMockUserForTest(id: 'user-u06', name: '김탈퇴');

  // ─── Router-based Tests ─────────────────────────────────────────────────

  group('IT-U06: 계정 삭제 wizard — 라우팅 및 렌더링', () {
    final capture = GoldenCapture('cuj_u06');

    testWidgets('비로그인 사용자는 탈퇴 사유 페이지에 접근할 수 없다', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/my/privacy/delete/reason',
        ),
      );
      await tester.pump();
      await tester.pump();

      // /my 하위 경로는 보호됨 → /login으로 리다이렉트
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('로그인 사용자는 탈퇴 사유 선택 페이지에 접근할 수 있다', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/my/privacy/delete/reason',
          additionalOverrides: _deletionRouterOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      await capture.setup(tester, 0);

      expect(find.byType(DeletionReasonPage), findsOneWidget);
      expect(find.text('탈퇴 사유'), findsOneWidget);
    });

    testWidgets('탈퇴 안내 페이지 — 삭제 정보/법정 보존 정보 섹션 렌더링', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/my/privacy/delete/info',
          additionalOverrides: _deletionRouterOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      await capture.after(tester, 1);

      expect(find.byType(DeletionInfoPage), findsOneWidget);
      expect(find.text('삭제되는 정보'), findsOneWidget);
      expect(find.text('법정 보존 정보'), findsOneWidget);
      expect(find.text('유예 기간 안내'), findsOneWidget);
    });

    testWidgets('탈퇴 완료 페이지 렌더링', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/my/privacy/delete/complete',
          additionalOverrides: _deletionRouterOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      await capture.after(tester, 2);

      expect(find.byType(DeletionCompletePage), findsOneWidget);
      expect(find.text('탈퇴 요청이 완료됐어요'), findsOneWidget);
      expect(find.textContaining('7일'), findsWidgets);
    });
  });

  // ─── Widget-level Interaction Tests ─────────────────────────────────────

  group('IT-U06: 탈퇴 사유 선택 페이지 인터랙션', () {
    Widget buildReasonPage({
      _SpyDeletionCoordinator? coordinator,
    }) {
      final spy = coordinator ?? _SpyDeletionCoordinator();
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((_) => testUser),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          accountDeletionControllerProvider.overrideWith(
            _FakeDeletionController.new,
          ),
          accountDeletionCoordinatorProvider.overrideWith((ref) => spy),
        ],
        child: const MaterialApp(
          home: DeletionReasonPage(),
        ),
      );
    }

    testWidgets('탈퇴 사유 선택 전 — 다음 버튼 비활성화', (tester) async {
      await tester.pumpWidget(buildReasonPage());
      await tester.pumpAndSettle();

      // '다음' 버튼은 사유 미선택 시 비활성
      final nextButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '다음'),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('탈퇴 사유 선택 후 — 다음 버튼 활성화', (tester) async {
      await tester.pumpWidget(buildReasonPage());
      await tester.pumpAndSettle();

      // 첫 번째 사유 선택 (더 이상 쓰지 않아요)
      await tester.tap(find.text('더 이상 쓰지 않아요').first);
      await tester.pump();

      final nextButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '다음'),
      );
      expect(nextButton.onPressed, isNotNull);
    });

    testWidgets('선택하지 않고 계속하기 → coordinator.pushInfo(reason: null)', (
      tester,
    ) async {
      final spy = _SpyDeletionCoordinator();
      await tester.pumpWidget(buildReasonPage(coordinator: spy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('선택하지 않고 계속하기'));
      await tester.pump();

      expect(spy.pushInfoCalled, isTrue);
      expect(spy.lastPushInfoReason, isNull);
    });

    testWidgets('사유 선택 후 다음 → coordinator.pushInfo(reason: 선택된 사유)', (
      tester,
    ) async {
      final spy = _SpyDeletionCoordinator();
      await tester.pumpWidget(buildReasonPage(coordinator: spy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('더 이상 쓰지 않아요').first);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '다음'));
      await tester.pump();

      await capture.after(tester, 3);

      expect(spy.pushInfoCalled, isTrue);
      expect(spy.lastPushInfoReason, isNotNull);
      expect(
        spy.lastPushInfoReason!.reasonCode,
        WithdrawalReasonCode.noLongerUse,
      );
    });
  });

  group('IT-U06: 탈퇴 본인 확인 페이지 인터랙션', () {
    Widget buildVerifyPage({
      required User user,
      _FakeDeletionController? controller,
      _SpyDeletionCoordinator? coordinator,
    }) {
      final spy = coordinator ?? _SpyDeletionCoordinator();
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((_) => user),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          accountDeletionControllerProvider.overrideWith(
            controller != null ? () => controller : _FakeDeletionController.new,
          ),
          accountDeletionCoordinatorProvider.overrideWith((ref) => spy),
        ],
        child: const MaterialApp(
          home: DeletionVerifyPage(reasonCode: 'no_longer_use'),
        ),
      );
    }

    testWidgets('이메일 유저 — 비밀번호 입력 필드 표시', (tester) async {
      final emailUser = _makeEmailUser();
      await tester.pumpWidget(buildVerifyPage(user: emailUser));
      await tester.pump();

      expect(find.text('비밀번호'), findsOneWidget);
      expect(find.text('탈퇴 요청'), findsOneWidget);
    });

    testWidgets('소셜 유저 — 소셜 재인증 안내 표시', (tester) async {
      final socialUser = _makeSocialUser();
      await tester.pumpWidget(buildVerifyPage(user: socialUser));
      await tester.pump();

      expect(find.text('소셜 로그인 계정은 다음 단계에서 재인증이 진행돼요.'), findsOneWidget);
    });

    testWidgets('빈 비밀번호 제출 → 에러 메시지 표시', (tester) async {
      final emailUser = _makeEmailUser();
      await tester.pumpWidget(buildVerifyPage(user: emailUser));
      await tester.pump();

      // 비밀번호 입력 없이 탈퇴 요청 탭
      await tester.tap(find.text('탈퇴 요청'));
      await tester.pump();

      await capture.error(tester, 4);

      expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);
    });

    testWidgets('비밀번호 입력 후 탈퇴 요청 확인 → coordinator.goComplete() 호출', (
      tester,
    ) async {
      final emailUser = _makeEmailUser();
      final spy = _SpyDeletionCoordinator();
      await tester.pumpWidget(
        buildVerifyPage(user: emailUser, coordinator: spy),
      );
      await tester.pump();

      // 비밀번호 입력
      await tester.enterText(find.byType(TextField), 'password123');
      await tester.pump();

      // 탈퇴 요청 탭 → reauthenticate → 확인 다이얼로그
      await tester.tap(find.text('탈퇴 요청'));
      await tester.pumpAndSettle();

      expect(find.text('정말 탈퇴할까요?'), findsOneWidget);
      await capture.before(tester, 5);

      // 다이얼로그 확인 버튼 탭 → goComplete() 호출
      await tester.tap(find.text('탈퇴 요청').last);
      await tester.pumpAndSettle();

      expect(spy.goCompleteCalled, isTrue);
    });
  });
}

// ─── Helpers ────────────────────────────────────────────────────────────────

User _makeEmailUser() {
  final user = MockUser();
  when(() => user.id).thenReturn('email-user-001');
  when(() => user.email).thenReturn('test@example.com');
  when(() => user.appMetadata).thenReturn(const {'provider': 'email'});
  when(() => user.identities).thenReturn(const []);
  when(() => user.userMetadata).thenReturn({'full_name': '이메일유저'});
  return user;
}

User _makeSocialUser() {
  final user = MockUser();
  when(() => user.id).thenReturn('social-user-001');
  when(() => user.email).thenReturn('social@example.com');
  when(() => user.appMetadata).thenReturn(const {'provider': 'google'});
  when(() => user.identities).thenReturn(const []);
  when(() => user.userMetadata).thenReturn({'full_name': '소셜유저'});
  return user;
}

// ─── Fakes ───────────────────────────────────────────────────────────────────

class _FakeAccountRepository extends AccountRepository {
  _FakeAccountRepository() : super(_MockSupabaseClient());

  @override
  Future<DeletionStatus?> getDeletionStatus() async => null;

  @override
  Future<void> reauthenticate(String? password) async {}

  @override
  Future<DeletionStatus> deleteAccount(WithdrawalReason? reason) async =>
      DeletionStatus.fromDeletedAt(DateTime(2026, 3, 31));

  @override
  Future<void> cancelDeletion() async {}
}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _FakeDeletionController extends AccountDeletionController {
  @override
  FutureOr<DeletionStatus?> build() async => null;

  @override
  Future<void> reauthenticate(String? password) async {}

  @override
  Future<DeletionStatus?> requestDeletion({WithdrawalReason? reason}) async =>
      DeletionStatus.fromDeletedAt(DateTime(2026, 3, 31));
}

/// Spy coordinator: records navigation method calls without actual routing.
class _SpyDeletionCoordinator extends AccountDeletionCoordinator {
  _SpyDeletionCoordinator()
    : super(
        GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      );
  bool pushInfoCalled = false;
  WithdrawalReason? lastPushInfoReason;
  bool pushVerifyCalled = false;
  bool goCompleteCalled = false;

  @override
  void start() {}

  @override
  void pushInfo({WithdrawalReason? reason}) {
    pushInfoCalled = true;
    lastPushInfoReason = reason;
  }

  @override
  void pushVerify({WithdrawalReason? reason}) {
    pushVerifyCalled = true;
  }

  @override
  void goComplete() {
    goCompleteCalled = true;
  }
}
