// MDS screen: event_application_detail_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/event_application_detail_page/
//
// 출력: docs/infra/mds-emulator-render/event_application_detail_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventApplicationDetailPageBuilder>(
  screen: 'event_application_detail_page',
  mdsSpec: 'apps/mds/docs/public/specs/event_application_detail_page/',
  builder: EventApplicationDetailPageBuilder.new,
  states: [
    MdsState('state-pending-review', (b) => b.pendingReview(), mdsIndex: 1),
    MdsState('state-approved', (b) => b.approved(), mdsIndex: 2),
    MdsState('state-rejected', (b) => b.rejected(), mdsIndex: 3),
    MdsState('state-paid', (b) => b.paid(), mdsIndex: 4),
    MdsState('state-reject-dialog', (b) => b.rejectDialog(), mdsIndex: 5),
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 6,
      infiniteAnimation: true,
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
