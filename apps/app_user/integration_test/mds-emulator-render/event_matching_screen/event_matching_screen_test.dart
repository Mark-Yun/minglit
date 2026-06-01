// MDS screen: event_matching_screen
// 대응 MDS: apps/mds/docs/public/specs/event_matching_screen/
//
// 출력: docs/infra/mds-emulator-render/event_matching_screen/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventMatchingScreenBuilder>(
  screen: 'event_matching_screen',
  mdsSpec: 'apps/mds/docs/public/specs/event_matching_screen/',
  builder: EventMatchingScreenBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-default-2', (b) => b.defaultState(), mdsIndex: 2),
    MdsState('state-default-3', (b) => b.defaultState(), mdsIndex: 3),
    MdsState('state-default-4', (b) => b.defaultState(), mdsIndex: 4),
    MdsState('state-default-5', (b) => b.defaultState(), mdsIndex: 5),
    MdsState('state-default-6', (b) => b.defaultState(), mdsIndex: 6),
    MdsState('state-default-7', (b) => b.defaultState(), mdsIndex: 7),
  ],
);

void main() => MdsRenderEngine.run(catalog);
