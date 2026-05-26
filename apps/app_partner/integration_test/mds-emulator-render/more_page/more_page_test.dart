// MDS screen: more_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/more_page/
//
// 출력: docs/infra/mds-emulator-render/more_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<MorePageBuilder>(
  screen: 'more_page',
  mdsSpec: 'apps/mds/docs/public/specs/more_page/',
  builder: MorePageBuilder.new,
  states: [
    // Baseline: 전권 파트너 (정산 권한 있음)
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    // Limited permissions: 정산 권한 없음 (계좌 관리 tile 미노출)
    MdsState(
      'state-limited-permissions',
      (b) => b.limitedPermissionsState(),
      mdsIndex: 2,
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
