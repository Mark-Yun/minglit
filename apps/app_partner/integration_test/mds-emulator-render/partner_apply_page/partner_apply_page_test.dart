// MDS screen: partner_apply_page
// 대응 MDS: apps/mds/docs/public/specs/partner_apply_page/
//
// 출력: docs/infra/mds-emulator-render/partner_apply_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerApplyPageBuilder>(
  screen: 'partner_apply_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_apply_page/',
  builder: PartnerApplyPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
  ],
);

void main() => MdsRenderEngine.run(catalog);
