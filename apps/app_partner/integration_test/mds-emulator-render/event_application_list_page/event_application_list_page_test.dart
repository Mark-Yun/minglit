// MDS screen: event_application_list_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/event_application_list_page/
//
// 출력: docs/infra/mds-emulator-render/event_application_list_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventApplicationListPageBuilder>(
  screen: 'event_application_list_page',
  mdsSpec: 'apps/mds/docs/public/specs/event_application_list_page/',
  builder: EventApplicationListPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-empty', (b) => b.empty(), mdsIndex: 2),
    MdsState('state-asymmetric', (b) => b.asymmetric(), mdsIndex: 3),
    MdsState('state-over-capacity', (b) => b.overCapacity(), mdsIndex: 4),
    MdsState('state-full-capacity', (b) => b.fullCapacity(), mdsIndex: 5),
    MdsState('state-approved-tab', (b) => b.approvedTab(), mdsIndex: 6),
    MdsState('state-rejected-tab', (b) => b.rejectedTab(), mdsIndex: 7),
    MdsState('state-refund-tab', (b) => b.refundTab(), mdsIndex: 8),
    MdsState('state-list-tab-empty', (b) => b.listTabEmpty(), mdsIndex: 9),
  ],
);

void main() => MdsRenderEngine.run(catalog);
