// MDS screen: my_tickets_page
// 대응 MDS: apps/mds/docs/public/specs/my_tickets_page/
//
// 출력: docs/infra/mds-emulator-render/my_tickets_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<MyTicketsPageBuilder>(
  screen: 'my_tickets_page',
  mdsSpec: 'apps/mds/docs/public/specs/my_tickets_page/',
  builder: MyTicketsPageBuilder.new,
  states: [
    MdsState(
      'state-active-banners',
      (b) => b.withActiveBanners(),
      mdsIndex: 1,
    ),
    MdsState('state-empty', (b) => b.empty(), mdsIndex: 2),
    // 현재 구현에는 별도 auth guard UI가 없어 logged-out은 empty 표현으로 캡처.
    MdsState(
      'state-logged-out',
      (b) => b.empty(),
      mdsIndex: 3,
    ),
    MdsState('state-dark-empty', (b) => b.empty().dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
