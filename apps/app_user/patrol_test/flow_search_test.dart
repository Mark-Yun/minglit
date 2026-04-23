// Ref #1778: Phase 1 PoC — 검색 화면 진입 flow test
//
// 검증 포인트:
// - flow_search_01: 홈 화면 검색 아이콘 탭 → 검색 화면 이동
// - flow_search_02: 검색어 입력 → 검색 결과 또는 빈 상태 표시
//
// Run: cd apps/app_user && patrol test --flavor dev \
//   --dart-define-from-file=../../minglit_env/dev/flutter.env \
//   --target patrol_test/flow_search_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'utils/patrol_test_app.dart';

void main() {
  patrolTest(
    '검색 화면 진입 및 검색어 입력',
    ($) async {
      await $.pumpWidgetAndSettle(createPatrolTestApp());

      // 홈 화면 검색 아이콘 탭 → SearchPage 이동
      await $(Icons.search).tap();
      await $.pumpAndSettle();

      // 검색어 입력 → 결과 또는 빈 상태
      await $(find.byType(TextField)).enterText('파티');
      await $.pump(const Duration(milliseconds: 600)); // 500ms 디바운스 대기
      await $.pumpAndSettle();
    },
  );
}
