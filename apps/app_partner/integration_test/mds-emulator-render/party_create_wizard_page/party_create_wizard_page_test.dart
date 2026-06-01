// MDS screen: party_create_wizard_page
// 대응 MDS: apps/mds/docs/public/specs/party_create_wizard_page/
//
// 출력: docs/infra/mds-emulator-render/party_create_wizard_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartyCreateWizardPageBuilder>(
  screen: 'party_create_wizard_page',
  mdsSpec: 'apps/mds/docs/public/specs/party_create_wizard_page/',
  builder: PartyCreateWizardPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
  ],
);

void main() => MdsRenderEngine.run(catalog);
