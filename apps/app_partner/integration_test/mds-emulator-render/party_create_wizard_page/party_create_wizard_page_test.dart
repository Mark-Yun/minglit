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
    MdsState('state-default-2', (b) => b.defaultState(), mdsIndex: 2),
    MdsState('state-default-3', (b) => b.defaultState(), mdsIndex: 3),
    MdsState('state-default-4', (b) => b.defaultState(), mdsIndex: 4),
    MdsState('state-default-5', (b) => b.defaultState(), mdsIndex: 5),
    MdsState('state-default-6', (b) => b.defaultState(), mdsIndex: 6),
    MdsState('state-default-7', (b) => b.defaultState(), mdsIndex: 7),
    MdsState('state-default-8', (b) => b.defaultState(), mdsIndex: 8),
  ],
);

void main() => MdsRenderEngine.run(catalog);
