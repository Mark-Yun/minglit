// MDS screen: checkin_placeholder_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/checkin_placeholder_page/
//
// 출력: docs/infra/mds-emulator-render/checkin_placeholder_page/state-*.png
//
// state_4 (direct-scan 1event) 는 mobile_scanner (카메라) 의존 → 캡처 제외.

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<CheckinPlaceholderPageBuilder>(
  screen: 'checkin_placeholder_page',
  mdsSpec: 'apps/mds/docs/public/specs/checkin_placeholder_page/',
  builder: CheckinPlaceholderPageBuilder.new,
  states: [
    // Loading — partner 정보 로딩 중 스피너
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 1,
      infiniteAnimation: true,
    ),
    // Error — partner 정보 로드 실패
    MdsState('state-error', (b) => b.error(), mdsIndex: 2),
    // Empty — 오늘 이벤트 없음
    MdsState('state-empty', (b) => b.withNoEvents(), mdsIndex: 3),
    // Direct dashboard — 오늘 이벤트 1개면 운영 화면으로 자동 진입
    MdsState(
      'state-direct-dashboard',
      (b) => b.withSingleEvent(),
      mdsIndex: 4,
    ),
    // Selection — 오늘 이벤트 2+개 (선택 목록)
    MdsState('state-selection', (b) => b.withMultipleEvents(2), mdsIndex: 5),
    // Dark variant
    MdsState('state-selection-dark', (b) => b.withMultipleEvents(2).dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
