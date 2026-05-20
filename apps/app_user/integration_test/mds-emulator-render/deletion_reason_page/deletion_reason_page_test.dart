// MDS screen: deletion_reason_page
// 대응 MDS: apps/mds/docs/public/specs/deletion_reason_page/
//
// 출력: docs/infra/mds-emulator-render/deletion_reason_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<DeletionReasonPageBuilder>(
  screen: 'deletion_reason_page',
  mdsSpec: 'apps/mds/docs/public/specs/deletion_reason_page/',
  builder: DeletionReasonPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b, mdsIndex: 1),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
