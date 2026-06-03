// MDS screen: event_checked_in_screen
// 대응 MDS: apps/mds/docs/public/specs/event_checked_in_screen/
//
// 출력: docs/infra/mds-emulator-render/event_checked_in_screen/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventCheckedInScreenBuilder>(
  screen: 'event_checked_in_screen',
  mdsSpec: 'apps/mds/docs/public/specs/event_checked_in_screen/',
  builder: EventCheckedInScreenBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-default-2', (b) => b.defaultState(), mdsIndex: 2),
    MdsState('state-default-3', (b) => b.defaultState(), mdsIndex: 3),
    MdsState('state-default-4', (b) => b.defaultState(), mdsIndex: 4),
  ],
);

void main() => MdsRenderEngine.run(catalog);
