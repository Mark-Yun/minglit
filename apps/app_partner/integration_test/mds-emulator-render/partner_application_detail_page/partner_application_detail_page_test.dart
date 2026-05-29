// MDS screen: partner_application_detail_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/partner_application_detail_page/
//
// 출력: docs/infra/mds-emulator-render/partner_application_detail_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerApplicationDetailPageBuilder>(
  screen: 'partner_application_detail_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_application_detail_page/',
  builder: PartnerApplicationDetailPageBuilder.new,
  states: [
    MdsState('state-pending', (b) => b.pending(), mdsIndex: 1),
    MdsState('state-approved', (b) => b.approved(), mdsIndex: 2),
    MdsState('state-rejected', (b) => b.rejected(), mdsIndex: 3),
    MdsState(
      'state-needs-correction',
      (b) => b.needsCorrection(),
      mdsIndex: 4,
    ),
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 5,
      infiniteAnimation: true,
    ),
    MdsState('state-not-found', (b) => b.notFound(), mdsIndex: 6),
  ],
);

void main() => MdsRenderEngine.run(catalog);
