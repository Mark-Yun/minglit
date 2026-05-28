// MDS screen: partner_events_page
// 대응 MDS: apps/mds/docs/public/specs/partner_events_page/
//
// 출력: docs/infra/mds-emulator-render/partner_events_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerEventsPageBuilder>(
  screen: 'partner_events_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_events_page/',
  builder: PartnerEventsPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.withDefault(), mdsIndex: 1),
    MdsState('state-empty-events', (b) => b.withEmpty(), mdsIndex: 2),
    MdsState(
      'state-loading',
      (b) => b.withLoading(),
      mdsIndex: 3,
      infiniteAnimation: true,
    ),
    MdsState('state-error', (b) => b.withError(), mdsIndex: 4),
  ],
);

void main() => MdsRenderEngine.run(catalog);
