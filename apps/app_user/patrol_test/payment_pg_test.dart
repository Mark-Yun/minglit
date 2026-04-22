// Phase 3: iamport PG payment WebView test
// Requires:
//   - Real device/emulator + patrol_cli
//   - PG sandbox credentials (see docs/features/patrol-introduction/)
//
<<<<<<<< HEAD:apps/app_user/emulator_test/payment_pg_test.dart
// Run: cd apps/app_user && patrol test emulator_test/payment_pg_test.dart
========
// Fix #1673: patrol_cli 4.x 문법으로 특정 테스트 실행
// Run: cd apps/app_user && patrol test --target patrol_test/payment_pg_test.dart
>>>>>>>> origin/dev:apps/app_user/patrol_test/payment_pg_test.dart

import 'package:patrol/patrol.dart';

void main() {
  // TODO(#1436): PG sandbox 설정 + 테스트 데이터 준비 후 skip 제거
  patrolTest(
    '이벤트 신청 → PG 결제 → 완료',
    skip: true,
    ($) async {
      // await $.pumpWidgetAndSettle(const App());
      //
      // 이벤트 상세 → 신청 → 결제 진입
      //
      // iamport WebView — Patrol v4 platform API로 네이티브 제어
      // await $.platform.tap(Selector(text: '카드결제'));
      // await $.platform.enterText(
      //   Selector(resourceId: 'card-number'),
      //   '4242424242424242',
      // );
      // await $.platform.tap(Selector(text: '결제하기'));
      //
      // Flutter 복귀 — 결제 완료
      // await $.pumpAndSettle();
      // expect($('결제 완료'), findsOneWidget);
    },
  );
}
