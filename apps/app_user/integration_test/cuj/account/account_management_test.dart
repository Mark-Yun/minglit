// CUJ tests — account / account-management
//
// 대응 spec: docs/features/account/account-management/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/cuj_test.dart';

class _VerificationHost extends StatelessWidget {
  const _VerificationHost({
    required this.isVerified,
    required this.onCertification,
  });

  final ValueNotifier<bool> isVerified;
  final VoidCallback onCertification;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isVerified,
      builder: (context, verified, _) {
        return AccountManagementPage(
          onLogout: () {},
          onDeleteAccount: () {},
          onCertification: onCertification,
          isVerified: verified,
        );
      },
    );
  }
}

class _LogoutRedirectHost extends StatelessWidget {
  const _LogoutRedirectHost({required this.loggedOut});

  final ValueNotifier<bool> loggedOut;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: loggedOut,
      builder: (context, isLoggedOut, _) {
        if (isLoggedOut) {
          return const Scaffold(body: Center(child: Text('로그인 화면')));
        }
        return AccountManagementPage(
          onLogout: () => loggedOut.value = true,
          onDeleteAccount: () {},
        );
      },
    );
  }
}

class _ParentPage extends StatelessWidget {
  const _ParentPage({required this.accountPage});

  final Widget accountPage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부모 페이지')),
      body: Center(
        child: FilledButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => accountPage),
            );
          },
          child: const Text('계정 관리 열기'),
        ),
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  cujGroup('1-1', '(user) 본인인증 미완 상태에서 진입', () {
    cujCase(
      'happy: 본인인증 타일(인증하기) 노출 + 탭 시 callback 호출',
      app: AccountManagementPage(
        onLogout: () {},
        onDeleteAccount: () {},
        onCertification: () {},
      ),
      body: (t) async {
        var tapped = 0;
        await t.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: AccountManagementPage(
              onLogout: () {},
              onDeleteAccount: () {},
              onCertification: () => tapped += 1,
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('본인인증'), findsOneWidget);
        expect(find.text('인증하기'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

        await t.tap(find.text('본인인증'));
        await t.pumpAndSettle();
        expect(tapped, 1);
      },
    );
  });

  cujGroup('1-2', '(user) 본인인증 완료 상태에서 진입', () {
    cujCase(
      'happy: 인증 완료 라벨/아이콘 노출 + 재진입 가능',
      app: AccountManagementPage(
        onLogout: () {},
        onDeleteAccount: () {},
        onCertification: () {},
        isVerified: true,
      ),
      body: (t) async {
        var tapped = 0;
        await t.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: AccountManagementPage(
              onLogout: () {},
              onDeleteAccount: () {},
              onCertification: () => tapped += 1,
              isVerified: true,
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('본인인증'), findsOneWidget);
        expect(find.text('인증 완료'), findsOneWidget);
        expect(find.byIcon(Icons.verified_user), findsOneWidget);

        await t.tap(find.text('본인인증'));
        await t.pumpAndSettle();
        expect(tapped, 1);
      },
    );
  });

  cujGroup('1-3', '(user) 본인인증 상태 외부 변경 즉시 반영', () {
    cujCase(
      'edge: 화면 노출 중 isVerified false->true 전환 시 즉시 UI 교체',
      app: _VerificationHost(
        isVerified: ValueNotifier<bool>(false),
        onCertification: _noop,
      ),
      body: (t) async {
        final verified = ValueNotifier<bool>(false);
        await t.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: _VerificationHost(
              isVerified: verified,
              onCertification: _noop,
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('인증하기'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

        verified.value = true;
        await t.pumpAndSettle();

        expect(find.text('인증 완료'), findsOneWidget);
        expect(find.byIcon(Icons.verified_user), findsOneWidget);
      },
    );
  });

  cujGroup('2-1', '(partner) 더보기 → 계정 관리 진입', () {
    cujCase(
      'happy: 파트너 프로필 타일만 노출, 본인인증 타일 미노출',
      app: const AccountManagementPage(
        onLogout: _noop,
        onDeleteAccount: _noop,
        onPartnerProfile: _noop,
      ),
      body: (t) async {
        expect(find.text('계정 관리'), findsWidgets);
        expect(find.text('파트너 프로필'), findsOneWidget);
        expect(find.text('본인인증'), findsNothing);
      },
    );
  });

  cujGroup('2-2', '(partner) 파트너 프로필 타일 탭 → SnackBar', () {
    cujCase(
      'happy: 파트너 프로필 탭 시 "준비 중입니다." 표시 + 화면 이동 없음',
      app: const AccountManagementPage(
        onLogout: _noop,
        onDeleteAccount: _noop,
        onPartnerProfile: _noop,
      ),
      body: (t) async {
        final messengerKey = GlobalKey<ScaffoldMessengerState>();

        await t.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            scaffoldMessengerKey: messengerKey,
            home: AccountManagementPage(
              onLogout: _noop,
              onDeleteAccount: _noop,
              onPartnerProfile: () {
                messengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('준비 중입니다.')),
                );
              },
            ),
          ),
        );
        await t.pumpAndSettle();

        await t.tap(find.text('파트너 프로필'));
        await t.pump();

        expect(find.text('준비 중입니다.'), findsOneWidget);
        expect(find.text('계정 관리'), findsWidgets);
      },
    );
  });

  cujGroup('3-1', '로그아웃 confirm 후 로그인 화면 복귀', () {
    cujCase(
      'happy: 확인 다이얼로그에서 로그아웃 선택 시 redirect host 표시',
      app: _LogoutRedirectHost(loggedOut: ValueNotifier<bool>(false)),
      body: (t) async {
        final loggedOut = ValueNotifier<bool>(false);
        await t.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: _LogoutRedirectHost(loggedOut: loggedOut),
          ),
        );
        await t.pumpAndSettle();

        await t.tap(find.text('로그아웃').first);
        await t.pumpAndSettle();

        expect(find.text('로그아웃 하시겠어요?'), findsOneWidget);

        await t.tap(find.text('로그아웃').last);
        await t.pumpAndSettle();

        expect(find.text('로그인 화면'), findsOneWidget);
      },
    );
  });

  cujGroup('3-2', '로그아웃 confirm 취소', () {
    cujCase(
      'edge: 취소 탭 시 로그아웃 callback 미호출',
      app: const AccountManagementPage(onLogout: _noop, onDeleteAccount: _noop),
      body: (t) async {
        var logoutCalled = 0;
        await t.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: AccountManagementPage(
              onLogout: () => logoutCalled += 1,
              onDeleteAccount: _noop,
            ),
          ),
        );
        await t.pumpAndSettle();

        await t.tap(find.text('로그아웃').first);
        await t.pumpAndSettle();

        expect(find.text('로그아웃 하시겠어요?'), findsOneWidget);

        await t.tap(find.text('취소'));
        await t.pumpAndSettle();

        expect(logoutCalled, 0);
        expect(find.text('계정 관리'), findsWidgets);
      },
    );
  });

  cujGroup('4-1', '회원 탈퇴 진입 (추가 확인 없이)', () {
    cujCase(
      'happy: 회원 탈퇴 탭 시 callback 즉시 호출',
      app: const AccountManagementPage(onLogout: _noop, onDeleteAccount: _noop),
      body: (t) async {
        var deleteCalled = 0;
        await t.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: AccountManagementPage(
              onLogout: _noop,
              onDeleteAccount: () => deleteCalled += 1,
            ),
          ),
        );
        await t.pumpAndSettle();

        await t.tap(find.text('회원 탈퇴'));
        await t.pumpAndSettle();

        expect(deleteCalled, 1);
      },
    );
  });

  cujGroup('4-2', '뒤로 가기 → 부모 페이지 복귀', () {
    cujCase(
      'happy: AppBar back 탭 시 부모 페이지로 pop',
      app: const _ParentPage(
        accountPage: AccountManagementPage(
          onLogout: _noop,
          onDeleteAccount: _noop,
        ),
      ),
      body: (t) async {
        await t.tap(find.text('계정 관리 열기'));
        await t.pumpAndSettle();

        expect(find.text('계정 관리'), findsWidgets);

        await t.tap(find.byType(BackButton));
        await t.pumpAndSettle();

        expect(find.text('부모 페이지'), findsOneWidget);
      },
    );
  });
}

void _noop() {}
