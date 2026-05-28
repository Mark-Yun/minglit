// MDS screen: partner_welcome_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/partner_welcome_page/
//
// 출력: docs/infra/mds-emulator-render/partner_welcome_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerWelcomePageBuilder>(
  screen: 'partner_welcome_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_welcome_page/',
  builder: PartnerWelcomePageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
  ],
);

void main() => MdsRenderEngine.run(catalog);
