// MDS screen: partner_guide
// 대응 MDS: apps/mds/docs/public/specs/partner_guide/
//
// 출력: docs/infra/mds-emulator-render/partner_guide/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerGuideBuilder>(
  screen: 'partner_guide',
  mdsSpec: 'apps/mds/docs/public/specs/partner_guide/',
  builder: PartnerGuideBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
  ],
);

void main() => MdsRenderEngine.run(catalog);
