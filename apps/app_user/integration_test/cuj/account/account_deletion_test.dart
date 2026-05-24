// CUJ tests — account / account-deletion
//
// 대응 spec: docs/features/account/account-deletion/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'dart:async';

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_verify_page.dart';
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

  bool throwOnReauth = false;
  bool throwOnDelete = false;
  DeletionStatus? statusToReturn;
  int cancelDeletionCallCount = 0;

  @override
  Future<DeletionStatus?> getDeletionStatus() async => statusToReturn;

  @override
  Future<void> reauthenticate(String? password) async {
    if (throwOnReauth) throw Exception('reauth failed');
  }

  @override
  Future<DeletionStatus> deleteAccount(WithdrawalReason? reason) async {
    if (throwOnDelete) throw Exception('delete failed');
    return DeletionStatus.fromDeletedAt(DateTime.now());
  }

  @override
  Future<void> cancelDeletion() async {
    cancelDeletionCallCount++;
  }
}

// Fix #2555: AuthController stub — signOut no-op to avoid real Supabase call.
class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}

  @override
  Future<void> signOut() async {}
}

_MockUser _socialUser() {
  final user = _MockUser();
  when(() => user.appMetadata).thenReturn(const {'provider': 'google'});
  when(() => user.identities).thenReturn(const []);
  return user;
}

_MockUser _passwordUser() {
  final user = _MockUser();
  when(() => user.appMetadata).thenReturn(const {'provider': 'email'});
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

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 탈퇴 사유 선택 후 안내 화면 진입
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '탈퇴 사유 선택 후 안내 화면 진입', () {
    List<dynamic> base() => [
      accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
    ];

    cujCase(
      'happy: 사유 선택 → 다음 → pushInfo(reason: ...)',
      app: const DeletionReasonPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('더 이상 쓰지 않아요'));
        await t.pumpAndSettle();

        // 다음 버튼 활성 확인 (FR-2)
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

        // reason 없이 pushInfo 호출 확인 (FR-2)
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

        verifyNever(() => coordinator.pushInfo(reason: any(named: 'reason')));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 안내 화면에서 손실/보존 정보 확인 후 진행
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '안내 화면에서 계속 진행 → pushVerify', () {
    List<dynamic> base() => [
      accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
    ];

    cujCase(
      'happy: 탈퇴 전 확인 화면 렌더 + 계속 진행 → pushVerify 호출 (FR-3)',
      app: const DeletionInfoPage(),
      overrides: base,
      body: (t) async {
        expect(find.text('탈퇴 전 확인'), findsOneWidget);

        await t.tap(find.text('계속 진행'));
        await t.pumpAndSettle();

        verify(
          () => coordinator.pushVerify(reason: any(named: 'reason')),
        ).called(1);
      },
    );

    cujCase(
      'happy: 사유 있는 경우 선택한 탈퇴 사유 섹션 표시 (FR-3)',
      app: const DeletionInfoPage(reasonCode: 'privacy_concern'),
      overrides: base,
      body: (t) async {
        expect(find.text('선택한 탈퇴 사유'), findsOneWidget);
        expect(find.text('계속 진행'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 소셜/비밀번호 본인 확인 흐름
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '소셜/비밀번호 본인 확인 흐름', () {
    late _FakeAccountRepository repo;

    setUp(() {
      repo = _FakeAccountRepository();
    });

    List<dynamic> socialBase() => [
      currentUserProvider.overrideWith((_) => _socialUser()),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      accountRepositoryProvider.overrideWithValue(repo),
      accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
    ];

    List<dynamic> passwordBase() => [
      currentUserProvider.overrideWith((_) => _passwordUser()),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      accountRepositoryProvider.overrideWithValue(repo),
      accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
    ];

    cujCase(
      'happy: 소셜 유저 → 소셜 재인증 안내 표시 (FR-4)',
      app: const DeletionVerifyPage(),
      overrides: socialBase,
      body: (t) async {
        // 소셜 유저: 비밀번호 필드 없음, 안내 카드만
        expect(find.text('비밀번호'), findsNothing);
        expect(find.textContaining('소셜 로그인 계정은'), findsOneWidget);
        expect(find.text('탈퇴 요청'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 비밀번호 유저 → 비밀번호 입력 필드 표시 (FR-4)',
      app: const DeletionVerifyPage(),
      overrides: passwordBase,
      body: (t) async {
        expect(find.text('비밀번호'), findsOneWidget);
        expect(find.text('탈퇴 요청'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 비밀번호 유저 → 비밀번호 미입력 → 탈퇴 요청 탭 시 에러 표시',
      app: const DeletionVerifyPage(),
      overrides: passwordBase,
      body: (t) async {
        // 비밀번호 입력 없이 탈퇴 요청 탭
        await t.tap(find.text('탈퇴 요청'));
        await t.pumpAndSettle();

        expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);
        verifyNever(() => coordinator.goComplete());
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-4: 최종 확인 다이얼로그에서 탈퇴 확정
  // ---------------------------------------------------------------------------

  cujGroup('1-4', '최종 확인 다이얼로그에서 탈퇴 확정', () {
    late _FakeAccountRepository repo;

    setUp(() {
      repo = _FakeAccountRepository();
    });

    List<dynamic> base() => [
      currentUserProvider.overrideWith((_) => _passwordUser()),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      accountRepositoryProvider.overrideWithValue(repo),
      accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
    ];

    cujCase(
      'happy: 비밀번호 입력 → 탈퇴 요청 탭 → 다이얼로그 표시 (FR-6)',
      app: const DeletionVerifyPage(),
      overrides: base,
      body: (t) async {
        await t.enterText(
          find.widgetWithText(TextField, '현재 비밀번호를 입력해주세요'),
          'test-password',
        );
        await t.pumpAndSettle();

        await t.tap(find.text('탈퇴 요청'));
        await t.pumpAndSettle();

        // 최종 확인 다이얼로그 표시 (FR-6: "정말 탈퇴할까요?")
        expect(find.text('정말 탈퇴할까요?'), findsOneWidget);
        expect(find.text('탈퇴 요청'), findsWidgets); // 다이얼로그 + 버튼
        expect(find.text('돌아가기'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 다이얼로그 돌아가기 → goComplete 미호출',
      app: const DeletionVerifyPage(),
      overrides: base,
      body: (t) async {
        await t.enterText(
          find.widgetWithText(TextField, '현재 비밀번호를 입력해주세요'),
          'test-password',
        );
        await t.pumpAndSettle();

        await t.tap(find.text('탈퇴 요청'));
        await t.pumpAndSettle();

        // 다이얼로그에서 돌아가기 선택 (FR-6: dismiss 시 진행 중단)
        await t.tap(find.text('돌아가기'));
        await t.pumpAndSettle();

        verifyNever(() => coordinator.goComplete());
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-5: 탈퇴 완료 화면 렌더링
  // ---------------------------------------------------------------------------

  cujGroup('1-5', '탈퇴 완료 화면 렌더링', () {
    List<dynamic> base() => [
      authControllerProvider.overrideWith(_FakeAuthController.new),
    ];

    cujCase(
      'happy: 체크 아이콘 + 안내 문구 + 확인 버튼 렌더 (FR-9)',
      app: const DeletionCompletePage(),
      overrides: base,
      body: (t) async {
        expect(find.text('탈퇴 요청이 완료됐어요'), findsOneWidget);
        expect(find.text('확인'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-6: 탈퇴 사유 익명 저장 payload
  // ---------------------------------------------------------------------------

  cujGroup('1-6', '탈퇴 사유 익명 저장 payload 전달', () {
    List<dynamic> base() => [
      accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
    ];

    cujCase(
      'happy: 기타 사유 입력 후 다음 → reason_code/reason_text만 전달 (FR-2, FR-7)',
      app: const DeletionReasonPage(),
      overrides: base,
      body: (t) async {
        final otherReasonTile = find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<WithdrawalReasonCode> &&
              widget.value == WithdrawalReasonCode.other,
        );
        await t.ensureVisible(otherReasonTile);
        await t.tap(otherReasonTile);
        await t.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        await t.enterText(find.byType(EditableText), '탈퇴 사유 상세 입력');
        await t.pumpAndSettle();

        await t.tap(find.text('다음'));
        await t.pumpAndSettle();

        final captured = verify(
          () => coordinator.pushInfo(reason: captureAny(named: 'reason')),
        ).captured;
        final reason = captured.single as WithdrawalReason;
        final payload = reason.toJson();

        expect(payload['reason_code'], 'other');
        expect(payload['reason_text'], '탈퇴 사유 상세 입력');
        expect(payload.containsKey('user_id'), isFalse);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 유예 기간 중 재로그인하면 복구 다이얼로그
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '유예 기간 중 재로그인하면 복구 다이얼로그', () {
    late StreamController<AuthState> authController;
    late _FakeAccountRepository repo;

    setUp(() {
      authController = StreamController<AuthState>.broadcast();
      repo = _FakeAccountRepository()
        ..statusToReturn = DeletionStatus.fromDeletedAt(
          DateTime.now().subtract(const Duration(days: 1)),
        );
    });

    tearDown(() async {
      await authController.close();
    });

    List<dynamic> base() => [
      authStateChangesProvider.overrideWith((_) => authController.stream),
      accountRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith((_) => _socialUser()),
      authControllerProvider.overrideWith(_FakeAuthController.new),
    ];

    cujCase(
      'happy: signedIn + 탈퇴 대기 상태 → 복구 다이얼로그 노출 (FR-14)',
      app: const PendingDeletionRecoveryListener(child: SizedBox.shrink()),
      overrides: base,
      body: (t) async {
        // signedIn 이벤트 발행 → 복구 다이얼로그 트리거
        authController.add(const AuthState(AuthChangeEvent.signedIn, null));
        // Fix #2555: PendingDeletionRecoveryListener 가 unawaited() 로
        // 비동기 체인 시작 — pumpAndSettle() 단독으로는 체인 완료 전에
        // settle 될 수 있어 pump 단계 추가.
        await t.pump();
        await t.pump(const Duration(milliseconds: 200));
        await t.pumpAndSettle();

        expect(find.text('탈퇴 대기 중인 계정입니다'), findsOneWidget);
        expect(find.text('취소할게요'), findsOneWidget);
        expect(find.text('탈퇴 유지'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 복구 다이얼로그에서 취소할게요 탭 → cancelDeletion 호출 (FR-15)',
      app: const PendingDeletionRecoveryListener(child: SizedBox.shrink()),
      overrides: base,
      body: (t) async {
        authController.add(const AuthState(AuthChangeEvent.signedIn, null));
        await t.pump();
        await t.pump(const Duration(milliseconds: 200));
        await t.pumpAndSettle();

        await t.tap(find.text('취소할게요'));
        await t.pumpAndSettle();

        // Fix #2555: cancelDeletion()이 실제로 호출됐는지 검증 (단순 dismiss 와 구분)
        expect(repo.cancelDeletionCallCount, 1);
        expect(find.text('탈퇴 대기 중인 계정입니다'), findsNothing);
      },
    );

    cujCase(
      'edge: signedIn 없음 → 다이얼로그 미노출',
      app: const PendingDeletionRecoveryListener(child: SizedBox.shrink()),
      overrides: base,
      body: (t) async {
        // signedIn 이벤트 없이 다른 이벤트 (passwordRecovery)
        authController.add(
          const AuthState(AuthChangeEvent.passwordRecovery, null),
        );
        await t.pumpAndSettle();

        expect(find.text('탈퇴 대기 중인 계정입니다'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 유예 기간 경과 시 영구 삭제 (백엔드 CRON)
  // ---------------------------------------------------------------------------

  cujGroup('3-2', '유예 기간 경과 시 영구 삭제 (백엔드 CRON)', () {
    cujCase(
      'stub: CRON 영구 삭제/DI 차단은 Flutter integration test 범위 외',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-3: 30일 내 동일 DI 재가입 차단 (백엔드 인증)
  // ---------------------------------------------------------------------------

  cujGroup('3-3', '30일 내 동일 DI 재가입 차단 (백엔드 인증)', () {
    cujCase(
      'stub: DI 차단 테이블 조회/만료 계산은 Flutter integration test 범위 외',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        expect(true, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-4: 유예 기간 중 노출 차단 (RLS/서버 필터)
  // ---------------------------------------------------------------------------

  cujGroup('3-4', '유예 기간 중 알림·매칭·검색 노출 차단 (RLS)', () {
    cujCase(
      'stub: feed/search/push exclusion은 서버 정책 검증 범위',
      app: const Placeholder(),
      overrides: () => [],
      body: (t) async {
        expect(true, isTrue);
      },
    );
  });
}
