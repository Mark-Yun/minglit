// CUJ tests — account / account-management (app_partner)
//
// 대응 spec: docs/features/account/account-management/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/cuj_test.dart';

// CUJ 2-2: wrapper that replicates the route's onPartnerProfile SnackBar logic.
class _PartnerAccountManagementWrapper extends StatelessWidget {
  const _PartnerAccountManagementWrapper();

  @override
  Widget build(BuildContext context) {
    return AccountManagementPage(
      onPartnerProfile: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('준비 중입니다.')),
      ),
      onLogout: () {},
      onDeleteAccount: () {},
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 2-1: (partner) 더보기 → 계정 관리 진입
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '(partner) 파트너 모드 계정 관리 진입', () {
    cujCase(
      'happy: 파트너 프로필 타일 노출, 본인인증 타일 미노출 (FR-1, FR-5)',
      app: const AccountManagementPage(
        onPartnerProfile: _noop,
        onLogout: _noop,
        onDeleteAccount: _noop,
      ),
      body: (t) async {
        // 파트너 프로필 타일 노출 (partner only — FR-5)
        expect(find.text('파트너 프로필'), findsOneWidget);

        // 본인인증 타일 미노출 (user only — FR-1)
        expect(find.text('본인인증'), findsNothing);

        // 로그아웃 / 회원 탈퇴 공통 타일 노출
        expect(find.text('로그아웃'), findsOneWidget);
        expect(find.text('회원 탈퇴'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: (partner) 파트너 프로필 타일 탭 → SnackBar
  // ---------------------------------------------------------------------------

  cujGroup('2-2', '(partner) 파트너 프로필 타일 탭 → SnackBar', () {
    cujCase(
      'happy: 파트너 프로필 탭 → "준비 중입니다." SnackBar 노출 (FR-6)',
      app: const _PartnerAccountManagementWrapper(),
      body: (t) async {
        await t.tap(find.text('파트너 프로필'));
        await t.pumpAndSettle();

        expect(find.text('준비 중입니다.'), findsOneWidget);
      },
    );

    cujCase(
      'edge: SnackBar 표시 중 다른 타일 탭 가능 (비차단 — NFR-3)',
      app: const _PartnerAccountManagementWrapper(),
      body: (t) async {
        await t.tap(find.text('파트너 프로필'));
        await t.pumpAndSettle();

        // SnackBar 표시 중에도 로그아웃 타일 탭 가능
        expect(find.text('준비 중입니다.'), findsOneWidget);
        await t.tap(find.text('로그아웃'));
        await t.pumpAndSettle();

        // 로그아웃 confirm 다이얼로그 — 비차단 확인
        expect(find.text('로그아웃 하시겠어요?'), findsOneWidget);

        // 취소로 닫기
        await t.tap(find.widgetWithText(TextButton, '취소'));
        await t.pumpAndSettle();
      },
    );
  });
}

// Const-compatible no-op callback for const widget declarations.
void _noop() {}
