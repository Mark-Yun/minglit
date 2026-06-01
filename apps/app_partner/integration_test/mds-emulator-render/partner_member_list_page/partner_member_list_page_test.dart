// MDS screen: partner_member_list_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/partner_member_list_page/
//
// 출력: docs/infra/mds-emulator-render/partner_member_list_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerMemberListPageBuilder>(
  screen: 'partner_member_list_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_member_list_page/',
  builder: PartnerMemberListPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-empty', (b) => b.empty(), mdsIndex: 2),
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 3,
      infiniteAnimation: true,
    ),
    MdsState('state-error', (b) => b.error(), mdsIndex: 4),
    MdsState(
      'state-invite-snackbar',
      (b) => b.inviteSnackbar(),
      mdsIndex: 5,
      infiniteAnimation: true,
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
