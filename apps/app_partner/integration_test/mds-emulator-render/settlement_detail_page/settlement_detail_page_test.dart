// MDS screen: settlement_detail_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/settlement_detail_page/
//
// 출력: docs/infra/mds-emulator-render/settlement_detail_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<SettlementDetailPageBuilder>(
  screen: 'settlement_detail_page',
  mdsSpec: 'apps/mds/docs/public/specs/settlement_detail_page/',
  builder: SettlementDetailPageBuilder.new,
  states: [
    MdsState('state-completed', (b) => b.completed(), mdsIndex: 1),
    MdsState('state-pending', (b) => b.pending(), mdsIndex: 2),
    MdsState('state-failed', (b) => b.failed(), mdsIndex: 3),
    MdsState('state-hold', (b) => b.hold(), mdsIndex: 4),
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 5,
      infiniteAnimation: true,
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
