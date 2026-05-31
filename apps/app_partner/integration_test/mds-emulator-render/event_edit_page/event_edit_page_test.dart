// MDS screen: event_edit_page
// 대응 MDS: apps/mds/docs/public/specs/event_edit_page/
//
// 출력: docs/infra/mds-emulator-render/event_edit_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventEditPageBuilder>(
  screen: 'event_edit_page',
  mdsSpec: 'apps/mds/docs/public/specs/event_edit_page/',
  builder: EventEditPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
  ],
);

void main() => MdsRenderEngine.run(catalog);
