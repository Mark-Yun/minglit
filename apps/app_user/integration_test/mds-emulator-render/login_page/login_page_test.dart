// MDS screen: login_page
// 대응 MDS: apps/mds/docs/public/specs/login_page/
//
// 출력: docs/infra/mds-emulator-render/login_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<LoginPageBuilder>(
  screen: 'login_page',
  mdsSpec: 'apps/mds/docs/public/specs/login_page/',
  builder: LoginPageBuilder.new,
  states: [
    MdsState('state-idle', (b) => b, mdsIndex: 1),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
