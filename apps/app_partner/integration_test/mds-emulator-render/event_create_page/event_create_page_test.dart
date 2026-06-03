// MDS screen: event_create_page
// 대응 MDS: apps/mds/docs/public/specs/event_create_page/
//
// 출력: docs/infra/mds-emulator-render/event_create_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventCreatePageBuilder>(
  screen: 'event_create_page',
  mdsSpec: 'apps/mds/docs/public/specs/event_create_page/',
  builder: EventCreatePageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-default-2', (b) => b.defaultState(), mdsIndex: 2),
    MdsState('state-default-3', (b) => b.defaultState(), mdsIndex: 3),
    MdsState('state-default-4', (b) => b.defaultState(), mdsIndex: 4),
    MdsState('state-default-5', (b) => b.defaultState(), mdsIndex: 5),
    MdsState('state-default-6', (b) => b.defaultState(), mdsIndex: 6),
  ],
);

void main() => MdsRenderEngine.run(catalog);
