// MDS screen: deletion_complete_page
// 대응 MDS: apps/mds/docs/public/specs/deletion_complete_page/
//
// 출력: docs/infra/mds-emulator-render/deletion_complete_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<DeletionCompletePageBuilder>(
  screen: 'deletion_complete_page',
  mdsSpec: 'apps/mds/docs/public/specs/deletion_complete_page/',
  builder: DeletionCompletePageBuilder.new,
  states: [
    MdsState('state-default', (b) => b, mdsIndex: 1),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
