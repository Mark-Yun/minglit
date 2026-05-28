// MDS screen: settlement_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/settlement_page/
//
// 출력: docs/infra/mds-emulator-render/settlement_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<SettlementPageBuilder>(
  screen: 'settlement_page',
  mdsSpec: 'apps/mds/docs/public/specs/settlement_page/',
  builder: SettlementPageBuilder.new,
  states: [
    // Loading — 대시보드/목록 초기 로딩.
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 1,
      infiniteAnimation: true,
    ),
    // Empty — 데이터 없음.
    MdsState('state-empty', (b) => b.empty(), mdsIndex: 2),
    // Error — 데이터 조회 실패.
    MdsState('state-error', (b) => b.error(), mdsIndex: 3),
  ],
);

void main() => MdsRenderEngine.run(catalog);
