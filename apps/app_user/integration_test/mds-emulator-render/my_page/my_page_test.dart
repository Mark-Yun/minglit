// MDS screen: my_page
// 대응 MDS: apps/mds/docs/public/specs/my_page/
//
// 출력: docs/infra/mds-emulator-render/my_page/state-*.png
//
// 로그인 상태는 currentUserProvider 이중 override 제약으로 현재 미포함.
// 로그인 상태 추가는 _engine/builder.dart 의 _commonRootOverrides 변경 후 가능.

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<MyPageBuilder>(
  screen: 'my_page',
  mdsSpec: 'apps/mds/docs/public/specs/my_page/',
  builder: MyPageBuilder.new,
  states: [
    MdsState('state-not-logged-in', (b) => b, mdsIndex: 2),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
