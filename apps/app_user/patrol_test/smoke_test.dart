// Ref #1778: Phase 1 PoC — 앱 기동 smoke test
//
// 검증 포인트:
// - 실 dev Supabase + Firebase 기동 성공
// - 홈 화면 도달 + 스크린샷 생성
//
// Run: cd apps/app_user && patrol test --flavor dev \
//   --dart-define-from-file=../../minglit_env/dev/flutter.env \
//   --target patrol_test/smoke_test.dart
import 'package:patrol/patrol.dart';

import 'utils/patrol_test_app.dart';

void main() {
  patrolTest(
    '앱 기동: 홈 화면 도달 및 하단 네비게이션 표시',
    ($) async {
      await $.pumpWidgetAndSettle(createPatrolTestApp());

      // 시나리오 스크린샷 — AI agent 리뷰용
      await $.native.screenshot(name: 'smoke_01_home_loaded');

      // 홈 화면 하단 탭 바 확인 (비로그인 상태)
      expect($('홈'), findsOneWidget);
    },
  );
}
