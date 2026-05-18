// MDS screen: deletion_info_page
// 대응 MDS: apps/mds/docs/public/specs/deletion_info_page/
//
// 출력: docs/infra/mds-emulator-render/deletion_info_page/state-*.png
//
// state 분류:
//   - state-no-reason*  : 탈퇴 사유를 건너뛰고 진입
//   - state-with-reason*: 탈퇴 사유(privacy_concern) 를 선택하고 진입

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

/// 탈퇴 사유 없이 진입하는 상태들.
final catalog = MdsCatalog<DeletionInfoPageBuilder>(
  screen: 'deletion_info_page',
  mdsSpec: 'apps/mds/docs/public/specs/deletion_info_page/',
  builder: DeletionInfoPageBuilder.new,
  states: [
    MdsState('state-no-reason', (b) => b, mdsIndex: 1),
    MdsState('state-no-reason-dark', (b) => b.dark()),
  ],
);

/// 탈퇴 사유를 선택하고 진입하는 상태들.
final catalogWithReason = MdsCatalog<DeletionInfoWithReasonBuilder>(
  screen: 'deletion_info_page',
  mdsSpec: 'apps/mds/docs/public/specs/deletion_info_page/',
  builder: DeletionInfoWithReasonBuilder.new,
  states: [
    MdsState('state-with-reason', (b) => b, mdsIndex: 2),
    MdsState('state-with-reason-dark', (b) => b.dark()),
  ],
);

void main() {
  MdsRenderEngine.run(catalog);
  MdsRenderEngine.run(catalogWithReason);
}
