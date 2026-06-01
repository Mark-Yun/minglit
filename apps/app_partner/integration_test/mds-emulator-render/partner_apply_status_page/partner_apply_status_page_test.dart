// MDS screen: partner_apply_status_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/partner_apply_status_page/
//
// 출력: docs/infra/mds-emulator-render/partner_apply_status_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerApplyStatusPageBuilder>(
  screen: 'partner_apply_status_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_apply_status_page/',
  builder: PartnerApplyStatusPageBuilder.new,
  states: [
    MdsState('state-pending', (b) => b.pending(), mdsIndex: 1),
    MdsState('state-needs-correction', (b) => b.needsCorrection(), mdsIndex: 2),
    MdsState(
      'state-needs-correction-comment',
      (b) => b.needsCorrectionWithComment(),
      mdsIndex: 3,
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
