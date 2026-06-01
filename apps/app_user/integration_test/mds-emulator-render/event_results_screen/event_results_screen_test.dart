// MDS screen: event_results_screen
// 대응 MDS: apps/mds/docs/public/specs/event_results_screen/
//
// 출력: docs/infra/mds-emulator-render/event_results_screen/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventResultsScreenBuilder>(
  screen: 'event_results_screen',
  mdsSpec: 'apps/mds/docs/public/specs/event_results_screen/',
  builder: EventResultsScreenBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
  ],
);

void main() => MdsRenderEngine.run(catalog);
