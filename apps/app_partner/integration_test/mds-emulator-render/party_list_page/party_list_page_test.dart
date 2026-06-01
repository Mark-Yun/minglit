// MDS screen: party_list_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/party_list_page/
//
// 출력: docs/infra/mds-emulator-render/party_list_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartyListPageBuilder>(
  screen: 'party_list_page',
  mdsSpec: 'apps/mds/docs/public/specs/party_list_page/',
  builder: PartyListPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-empty', (b) => b.emptyState(), mdsIndex: 2),
    MdsState(
      'state-loading',
      (b) => b.loadingState(),
      mdsIndex: 3,
      infiniteAnimation: true,
    ),
    MdsState('state-error', (b) => b.errorState(), mdsIndex: 4),
    MdsState('state-help', (b) => b.helpState(), mdsIndex: 5),
  ],
);

void main() => MdsRenderEngine.run(catalog);
