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
  ],
);

void main() => MdsRenderEngine.run(catalog);
