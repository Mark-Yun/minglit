// MDS screen: blocked_partners_page
// 대응 MDS: apps/mds/docs/public/specs/blocked_partners_page/
//
// 출력: docs/infra/mds-emulator-render/blocked_partners_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<BlockedPartnersPageBuilder>(
  screen: 'blocked_partners_page',
  mdsSpec: 'apps/mds/docs/public/specs/blocked_partners_page/',
  builder: BlockedPartnersPageBuilder.new,
  states: [
    MdsState('state-loading', (b) => b.loading(), mdsIndex: 1, infiniteAnimation: true),
    MdsState('state-empty', (b) => b.empty(), mdsIndex: 2),
    MdsState('state-with-partners', (b) => b.withPartners(), mdsIndex: 3),
    MdsState('state-dark', (b) => b.withPartners().dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
