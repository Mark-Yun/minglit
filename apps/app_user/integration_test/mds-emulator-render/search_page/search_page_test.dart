// MDS screen: search_page
// 대응 MDS: apps/mds/docs/public/specs/search_page/
//
// 출력: docs/infra/mds-emulator-render/search_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<SearchPageBuilder>(
  screen: 'search_page',
  mdsSpec: 'apps/mds/docs/public/specs/search_page/',
  builder: SearchPageBuilder.new,
  states: [
    MdsState('state-empty', (b) => b, mdsIndex: 1),
    MdsState('state-with-results', (b) => b.withResults(3), mdsIndex: 2),
    MdsState('state-no-results', (b) => b.withNoResults(), mdsIndex: 3),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
