// MDS screen: partner_home_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/partner_home_page/
//
// 출력: docs/infra/mds-emulator-render/partner_home_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerHomePageBuilder>(
  screen: 'partner_home_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_home_page/',
  builder: PartnerHomePageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
  ],
);

void main() => MdsRenderEngine.run(catalog);
