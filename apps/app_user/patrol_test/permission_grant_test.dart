// Phase 2: Native permission tests
// Requires real device/emulator + patrol_cli to run:
//   cd apps/app_user && patrol test patrol_test/permission_grant_test.dart
//
// These tests verify OS-level permission dialogs that cannot be tested
// with Flutter's integration_test framework.

import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    '카메라 권한 허용 → 카메라 프리뷰 표시',
    skip: 'TODO(#1436): App 초기화 + 테스트 계정 로그인 구현 후 활성화',
    ($) async {
      // await $.pumpWidgetAndSettle(const App());
      //
      // QR 스캐너 진입 → OS 카메라 권한 다이얼로그
      // await $('QR 스캔').tap();
      // await $.platform.grantPermissionWhenInUse();
      //
      // 카메라 프리뷰 로드 확인
      // expect($(CameraPreview), findsOneWidget);
    },
  );

  patrolTest(
    '위치 권한 허용 → 위치 기반 추천 활성화',
    skip: 'TODO(#1436): App 초기화 + 테스트 계정 로그인 구현 후 활성화',
    ($) async {
      // await $.pumpWidgetAndSettle(const App());
      //
      // 위치 권한 요청 트리거
      // await $.platform.grantPermissionWhenInUse();
    },
  );

  patrolTest(
    '푸시 알림 권한 허용',
    skip: 'TODO(#1436): App 초기화 후 활성화',
    ($) async {
      // await $.pumpWidgetAndSettle(const App());
      //
      // 푸시 알림 권한 다이얼로그 → 허용
      // await $.platform.grantPermissionWhenInUse();
    },
  );
}
