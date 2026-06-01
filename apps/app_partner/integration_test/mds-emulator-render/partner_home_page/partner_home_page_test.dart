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
    MdsState('state-default-2', (b) => b.defaultState(), mdsIndex: 2),
    MdsState('state-default-3', (b) => b.defaultState(), mdsIndex: 3),
    MdsState('state-default-4', (b) => b.defaultState(), mdsIndex: 4),
    MdsState('state-default-5', (b) => b.defaultState(), mdsIndex: 5),
    MdsState('state-default-6', (b) => b.defaultState(), mdsIndex: 6),
    MdsState('state-default-7', (b) => b.defaultState(), mdsIndex: 7),
    MdsState('state-default-8', (b) => b.defaultState(), mdsIndex: 8),
  ],
);

void main() => MdsRenderEngine.run(catalog);
