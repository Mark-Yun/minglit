// MDS screen: event_now_bar
// 대응 MDS: apps/mds/docs/public/specs/event_now_bar/
//
// 출력: docs/infra/mds-emulator-render/event_now_bar/state-*.png
//
// Fix #2588: mds-render-coverage event-operation 카탈로그 등록

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventNowBarBuilder>(
  screen: 'event_now_bar',
  mdsSpec: 'apps/mds/docs/public/specs/event_now_bar/',
  builder: EventNowBarBuilder.new,
  states: [
    MdsState('state-waiting', (b) => b..waiting(), mdsIndex: 1),
    MdsState('state-check-in-ready', (b) => b..checkInReady(), mdsIndex: 2),
    MdsState('state-checked-in', (b) => b..checkedIn(), mdsIndex: 3),
    // state_4 (matchingReady): spec에 정의되나 EventNowBarState enum에 미구현.
    // matching(state_5)이 matchingReady를 대체하는 것으로 보임. 후속 spec 정합성 검토 필요.
    MdsState('state-matching', (b) => b..matching(), mdsIndex: 5),
    // Fix #2590: results 상태는 repeat() pulse animation — pumpAndSettle 불가.
    MdsState(
      'state-results',
      (b) => b..results(),
      mdsIndex: 6,
      infiniteAnimation: true,
    ),
    MdsState('state-ended', (b) => b..ended(), mdsIndex: 7),
    MdsState('state-offline', (b) => b..offline()),
    MdsState(
      'state-dark-waiting',
      (b) => b
        ..waiting()
        ..dark(),
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
