// MDS screen: event_application_manage_page
// 대응 MDS: apps/mds/docs/public/specs/event_application_manage_page/
//
// 출력: docs/infra/mds-emulator-render/event_application_manage_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventApplicationManagePageBuilder>(
  screen: 'event_application_manage_page',
  mdsSpec: 'apps/mds/docs/public/specs/event_application_manage_page/',
  builder: EventApplicationManagePageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-list', (b) => b.defaultState(), mdsIndex: 2),
    MdsState('state-loading', (b) => b.defaultState(), mdsIndex: 3),
    MdsState('state-empty', (b) => b.defaultState(), mdsIndex: 4),
    MdsState('state-error', (b) => b.defaultState(), mdsIndex: 5),
    MdsState('state-filtered', (b) => b.defaultState(), mdsIndex: 6),
    MdsState('state-dark', (b) => b.dark(), mdsIndex: 7),
  ],
);

void main() => MdsRenderEngine.run(catalog);
