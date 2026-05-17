// MDS screen: home_page
// 대응 MDS: apps/mds/docs/public/specs/home_page/
//
// 출력: docs/infra/mds-emulator-render/home_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<HomePageBuilder>(
  screen: 'home_page',
  mdsSpec: 'apps/mds/docs/public/specs/home_page/',
  builderFactory: HomePageBuilder.new,
  states: [
    MdsState('state-empty', (b) => b.empty(), mdsIndex: 1),
    MdsState('state-with-events', (b) => b.withEvents(3), mdsIndex: 2),
    MdsState('state-dark', (b) => b.empty().dark()),
    MdsState(
      'state-dark-with-events',
      (b) => b.withEvents(3).dark(),
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
