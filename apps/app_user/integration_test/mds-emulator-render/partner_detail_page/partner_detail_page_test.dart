// MDS screen: partner_detail_page
// 대응 MDS: apps/mds/docs/public/specs/partner_detail_page/
//
// 출력: docs/infra/mds-emulator-render/partner_detail_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerDetailPageBuilder>(
  screen: 'partner_detail_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_detail_page/',
  builder: PartnerDetailPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.withDefault(), mdsIndex: 1),
    MdsState(
      'state-loading',
      (b) => b.withLoading(),
      mdsIndex: 2,
      infiniteAnimation: true,
    ),
    MdsState('state-error', (b) => b.withError(), mdsIndex: 3),
    MdsState('state-not-found', (b) => b.withNotFound(), mdsIndex: 4),
    MdsState('state-empty-events', (b) => b.withEmptyEvents(), mdsIndex: 5),
  ],
);

void main() => MdsRenderEngine.run(catalog);
