// Phase 3: Kakao OAuth WebView login test
// Requires:
//   - Real device/emulator + patrol_cli
//   - Kakao test OAuth account credentials (see docs/features/patrol-introduction/)
//
// Run: cd apps/app_user && patrol test emulator_test/kakao_login_test.dart

import 'package:patrol/patrol.dart';

void main() {
  // TODO(#1436): 카카오 테스트 계정 준비 후 skip 제거
  patrolTest(
    '카카오 로그인 → 홈 화면 도달',
    skip: true,
    ($) async {
      // await $.pumpWidgetAndSettle(const App());
      //
      // 카카오 로그인 버튼 탭
      // await $('카카오로 시작').tap();
      //
      // WebView 내부 — Patrol v4 platform API로 네이티브 제어
      // await $.platform.tap(Selector(text: '전체 동의하고 계속하기'));
      // await $.platform.enterTextByIndex('test@test.com', index: 0);
      // await $.platform.enterTextByIndex('password1234!', index: 1);
      // await $.platform.tap(Selector(text: '로그인'));
      //
      // Flutter 레이어 복귀 — 홈 화면 확인
      // await $.pumpAndSettle();
      // expect($(HomePage), findsOneWidget);
    },
  );
}
