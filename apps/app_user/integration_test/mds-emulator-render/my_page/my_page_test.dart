// MDS screen: my_page
// 대응 MDS: apps/mds/docs/public/specs/my_page/
//
// 출력: docs/infra/mds-emulator-render/my_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<MyPageBuilder>(
  screen: 'my_page',
  mdsSpec: 'apps/mds/docs/public/specs/my_page/',
  builder: MyPageBuilder.new,
  states: [
    MdsState('state-authenticated', (b) => b.authenticated(), mdsIndex: 1),
    MdsState('state-unauthenticated', (b) => b, mdsIndex: 2),
    MdsState('state-dark', (b) => b.authenticated().dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
