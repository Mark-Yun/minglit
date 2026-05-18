// MDS screen: event_ongoing_banner
// 대응 MDS: apps/mds/docs/public/specs/event_ongoing_banner/
//
// 출력: docs/infra/mds-emulator-render/event_ongoing_banner/state-*.png
//
// Fix #2588: mds-render-coverage event-operation 카탈로그 등록

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventOngoingBannerBuilder>(
  screen: 'event_ongoing_banner',
  mdsSpec: 'apps/mds/docs/public/specs/event_ongoing_banner/',
  builder: EventOngoingBannerBuilder.new,
  states: [
    MdsState('state-waiting', (b) => b..waiting(), mdsIndex: 1),
    MdsState('state-check-in-ready', (b) => b..checkInReady(), mdsIndex: 2),
    MdsState('state-checked-in', (b) => b..checkedIn(), mdsIndex: 3),
    MdsState('state-matching-ready', (b) => b..matchingReady(), mdsIndex: 4),
    MdsState('state-matching', (b) => b..matching(), mdsIndex: 5),
    MdsState(
      'state-results-unviewed',
      (b) => b..resultsUnviewed(),
      mdsIndex: 6,
    ),
    MdsState(
      'state-results-viewed',
      (b) => b..resultsViewed(),
      mdsIndex: 7,
    ),
    MdsState('state-no-show', (b) => b..noShow(), mdsIndex: 8),
    MdsState('state-dark-waiting', (b) => b..waiting()..dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
