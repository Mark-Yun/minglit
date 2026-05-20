// MDS screen: account_management_page
// 대응 MDS: apps/mds/docs/public/specs/account_management_page/
//
// 출력: docs/infra/mds-emulator-render/account_management_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<AccountManagementPageBuilder>(
  screen: 'account_management_page',
  mdsSpec: 'apps/mds/docs/public/specs/account_management_page/',
  builder: AccountManagementPageBuilder.new,
  states: [
    MdsState('state-user-unverified', (b) => b, mdsIndex: 1),
    MdsState('state-user-verified', (b) => b.verified(), mdsIndex: 2),
    MdsState('state-partner', (b) => b.partnerMode(), mdsIndex: 3),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
