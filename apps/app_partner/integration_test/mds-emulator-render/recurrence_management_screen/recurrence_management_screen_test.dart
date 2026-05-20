// MDS screen: recurrence_management_screen (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/recurrence_management_screen/
//
// 출력: docs/infra/mds-emulator-render/recurrence_management_screen/state-*.png
//
// state_5 (confirm dialog overlay), state_7 (success snackbar) 는
// 실제 유저 액션 트리거 필요 → 카탈로그 외 UI test 에서 검증.

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<RecurrenceManagementScreenBuilder>(
  screen: 'recurrence_management_screen',
  mdsSpec: 'apps/mds/docs/public/specs/recurrence_management_screen/',
  builder: RecurrenceManagementScreenBuilder.new,
  states: [
    // Default/Active — 보라 '활성' 칩 + [일시정지 | 취소] 액션바
    MdsState('state-active', (b) => b.withActiveRule(), mdsIndex: 1),
    // Paused — tertiary '일시 정지' 칩 + [취소 | 재개] 액션바
    MdsState('state-paused', (b) => b.withPausedRule(), mdsIndex: 2),
    // Cancelled — error '취소됨' 칩 + 안내문 + 액션바 hidden
    MdsState('state-cancelled', (b) => b.withCancelledRule(), mdsIndex: 3),
    // No rule — '설정된 반복 규칙이 없습니다.' 중앙 텍스트
    MdsState('state-no-rule', (b) => b.withNoRule(), mdsIndex: 4),
    // Action loading — 버튼 disabled
    MdsState('state-action-loading', (b) => b.withActionLoading(), mdsIndex: 6),
    // Loading (fetch) — AsyncValueWidget 로딩
    MdsState('state-loading', (b) => b.loading(), mdsIndex: 8, infiniteAnimation: true),
    // Dark variant
    MdsState('state-active-dark', (b) => b.withActiveRule().dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
