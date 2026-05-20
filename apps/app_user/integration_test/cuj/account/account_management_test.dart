// CUJ tests — account / account-management (app_user)
//
// 대응 spec: docs/features/account/account-management/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/cuj_test.dart';

// CUJ 1-3: StatefulWidget for simulating external isVerified change.
class _VerifiedWrapper extends StatefulWidget {
  const _VerifiedWrapper();

  @override
  State<_VerifiedWrapper> createState() => _VerifiedWrapperState();
}

class _VerifiedWrapperState extends State<_VerifiedWrapper> {
  bool _isVerified = false;

  void setVerified({required bool value}) {
    setState(() => _isVerified = value);
  }

  @override
  Widget build(BuildContext context) {
    return AccountManagementPage(
      isVerified: _isVerified,
      onCertification: () {},
      onLogout: () {},
      onDeleteAccount: () {},
    );
  }
}

// CUJ 4-2: Wrapper that pushes AccountManagementPage onto Navigator stack.
class _PushWrapper extends StatelessWidget {
  const _PushWrapper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => AccountManagementPage(
                onCertification: () {},
                onLogout: () {},
                onDeleteAccount: () {},
              ),
            ),
          ),
          child: const Text('열기'),
        ),
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 1-1: (user) 본인인증 미완 상태에서 진입
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '(user) 본인인증 미완 상태에서 진입', () {
    var onCertCalled = false;

    cujCase(
      'happy: 본인인증 타일 "인증하기" subtitle 노출, 탭 → onCertification 호출',
      app: AccountManagementPage(
        onCertification: () => onCertCalled = true,
        onLogout: () {},
        onDeleteAccount: () {},
      ),
      body: (t) async {
        onCertCalled = false;

        expect(find.text('본인인증'), findsOneWidget);
        expect(find.text('인증하기'), findsOneWidget);

        await t.tap(find.text('본인인증'));
        await t.pumpAndSettle();

        expect(onCertCalled, isTrue);
      },
    );

    cujCase(
      'edge: isVerified 기본값(false) → 인증하기 표시',
      app: const AccountManagementPage(
        onCertification: _noop,
        onLogout: _noop,
        onDeleteAccount: _noop,
      ),
      body: (t) async {
        expect(find.text('인증하기'), findsOneWidget);
        expect(find.text('인증 완료'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: (user) 본인인증 완료 상태에서 진입
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '(user) 본인인증 완료 상태에서 진입', () {
    var onCertCalled = false;

    cujCase(
      'happy: 본인인증 타일 "인증 완료" subtitle 노출 + 탭 가능',
      app: AccountManagementPage(
        isVerified: true,
        onCertification: () => onCertCalled = true,
        onLogout: () {},
        onDeleteAccount: () {},
      ),
      body: (t) async {
        onCertCalled = false;

        expect(find.text('본인인증'), findsOneWidget);
        expect(find.text('인증 완료'), findsOneWidget);

        // Fix #1861: 인증 완료 후도 탭 가능 (다시 들어가도 막지 않음)
        await t.tap(find.text('본인인증'));
        await t.pumpAndSettle();

        expect(onCertCalled, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: (user) 본인인증 상태 외부 변경 즉시 반영
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '(user) 본인인증 상태 외부 변경 즉시 반영', () {
    cujCase(
      'happy: isVerified false→true → success 톤 즉시 교체 (깜빡임 X)',
      app: const _VerifiedWrapper(),
      body: (t) async {
        // 초기 미인증 상태 확인
        expect(find.text('인증하기'), findsOneWidget);
        expect(find.text('인증 완료'), findsNothing);

        // 외부에서 인증 완료 시뮬레이션 (provider rebuild → setState 동일 효과)
        t
            .state<_VerifiedWrapperState>(find.byType(_VerifiedWrapper))
            .setVerified(value: true);
        await t.pump();

        // UI 즉시 업데이트 확인 (깜빡임 없이 교체)
        expect(find.text('인증 완료'), findsOneWidget);
        expect(find.text('인증하기'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 로그아웃 confirm 후 로그인 화면 복귀
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '로그아웃 confirm 후 로그인 화면 복귀', () {
    var logoutCalled = false;

    cujCase(
      'happy: "로그아웃" 타일 탭 → confirm 다이얼로그 → "로그아웃" → onLogout 호출',
      app: AccountManagementPage(
        onCertification: () {},
        onLogout: () => logoutCalled = true,
        onDeleteAccount: () {},
      ),
      body: (t) async {
        logoutCalled = false;

        // 로그아웃 타일 탭
        await t.tap(find.text('로그아웃'));
        await t.pumpAndSettle();

        // MinglitAlert.showConfirm 다이얼로그 노출 확인 (FR-8)
        expect(find.text('로그아웃 하시겠어요?'), findsOneWidget);

        // 다이얼로그의 "로그아웃" 확인 버튼 탭
        await t.tap(find.widgetWithText(TextButton, '로그아웃'));
        await t.pumpAndSettle();

        expect(logoutCalled, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 로그아웃 confirm 취소
  // ---------------------------------------------------------------------------

  cujGroup('3-2', '로그아웃 confirm 취소', () {
    var logoutCalled = false;

    cujCase(
      'happy: "취소" 탭 → 다이얼로그 닫힘, onLogout 미호출',
      app: AccountManagementPage(
        onCertification: () {},
        onLogout: () => logoutCalled = true,
        onDeleteAccount: () {},
      ),
      body: (t) async {
        logoutCalled = false;

        await t.tap(find.text('로그아웃'));
        await t.pumpAndSettle();

        expect(find.text('로그아웃 하시겠어요?'), findsOneWidget);

        await t.tap(find.widgetWithText(TextButton, '취소'));
        await t.pumpAndSettle();

        expect(logoutCalled, isFalse);
        expect(find.text('로그아웃 하시겠어요?'), findsNothing);
      },
    );

    cujCase(
      'edge: scrim 탭 → 다이얼로그 닫힘, onLogout 미호출',
      app: AccountManagementPage(
        onCertification: () {},
        onLogout: () => logoutCalled = true,
        onDeleteAccount: () {},
      ),
      body: (t) async {
        logoutCalled = false;

        await t.tap(find.text('로그아웃'));
        await t.pumpAndSettle();

        // scrim 탭 — dialog 외부 좌상단 모서리
        await t.tapAt(const Offset(10, 10));
        await t.pumpAndSettle();

        expect(logoutCalled, isFalse);
        expect(find.text('로그아웃 하시겠어요?'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-1: 회원 탈퇴 진입 (추가 confirm 없이)
  // ---------------------------------------------------------------------------

  cujGroup('4-1', '회원 탈퇴 진입 (추가 confirm 없이)', () {
    var deleteAccountCalled = false;

    cujCase(
      'happy: 회원 탈퇴 탭 → onDeleteAccount 즉시 호출 (FR-10)',
      app: AccountManagementPage(
        onCertification: () {},
        onLogout: () {},
        onDeleteAccount: () => deleteAccountCalled = true,
      ),
      body: (t) async {
        deleteAccountCalled = false;

        await t.tap(find.text('회원 탈퇴'));
        await t.pumpAndSettle();

        // 추가 confirm dialog 없이 즉시 호출 확인 (FR-10)
        expect(deleteAccountCalled, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-2: 뒤로 가기 → 부모 페이지 복귀
  // ---------------------------------------------------------------------------

  cujGroup('4-2', '뒤로 가기 → 부모 페이지 복귀', () {
    cujCase(
      'happy: AppBar 뒤로 가기 → Navigator.pop → 이전 화면 복귀',
      app: const _PushWrapper(),
      body: (t) async {
        // AccountManagementPage 진입
        await t.tap(find.text('열기'));
        await t.pumpAndSettle();

        // Fix #2659: AccountManagementPage는 AppBar 제목 + settings group 헤더 양쪽에
        // '계정 관리' 텍스트가 있어 findsOneWidget 대신 '로그아웃' 로 페이지 진입 검증.
        expect(find.text('로그아웃'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);

        // AppBar 뒤로 가기
        await t.tap(find.byType(BackButton));
        await t.pumpAndSettle();

        // 부모 페이지 복귀 확인
        expect(find.text('열기'), findsOneWidget);
        expect(find.text('계정 관리'), findsNothing);
      },
    );
  });
}

// Const-compatible no-op callback for const widget declarations.
void _noop() {}
